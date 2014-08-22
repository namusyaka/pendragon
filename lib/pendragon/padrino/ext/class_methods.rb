module Pendragon
  module Padrino
    module ClassMethods
      CONTENT_TYPE_ALIASES = {:htm => :html} unless defined?(CONTENT_TYPE_ALIASES)
      ROUTE_PRIORITY       = {:high => 0, :normal => 1, :low => 2} unless defined?(ROUTE_PRIORITY)

      def router
        unless @router
          @router = ::Pendragon::Padrino::Router.new
          @router.configuration = Pendragon::Configuration.new
          if settings.respond_to?(:pendragon) && settings.pendragon.instance_of?(Hash)
            settings.pendragon.each_pair do |key, value|
              @router.configuration.send("#{key}=", value)
            end
          end
        end
        block_given? ? yield(@router) : @router
      end

      def compiled_router
        if @deferred_routes
          deferred_routes.each do |routes|
            routes.each do |(route, dest)|
              route.to(&dest)
              route.before_filters.flatten!
              route.after_filters.flatten!
            end
          end
          @deferred_routes = nil
        end
        router
      end

      def deferred_routes
        @deferred_routes ||= ROUTE_PRIORITY.map{[]}
      end

      def url(*args)
        params = args.extract_options! # parameters is hash at end
        names, params_array = args.partition{|a| a.is_a?(Symbol)}
        name = names[0, 2].join(" ").to_sym # route name is concatenated with underscores
        if params.is_a?(Hash)
          params[:format] = params[:format].to_s unless params[:format].nil?
          params = value_to_param(params)
        end
        url =
          if params_array.empty?
            compiled_router.path(name, params)
          else
            compiled_router.path(name, *(params_array << params))
          end
        rebase_url(url)
      rescue Pendragon::InvalidRouteException
        route_error = "route mapping for url(#{name.inspect}) could not be found!"
        raise ::Padrino::Routing::UnrecognizedException.new(route_error)
      end
      alias :url_for :url

      def recognize_path(path)
        responses = @router.recognize_path(path)
        [responses[0], responses[1]]
      end

      def rebase_url(url)
        if url.start_with?('/')
          new_url = ''
          new_url << conform_uri(uri_root) if defined?(uri_root)
          new_url << conform_uri(ENV['RACK_BASE_URI']) if ENV['RACK_BASE_URI']
          new_url << url
        else
          url.blank? ? '/' : url
        end
      end

      private

      def route(verb, path, *args, &block)
        options = case args.size
          when 2
            args.last.merge(:map => args.first)
          when 1
            map = args.shift if args.first.is_a?(String)
            if args.first.is_a?(Hash)
              map ? args.first.merge(:map => map) : args.first
            else
              {:map => map || args.first}
            end
          when 0
            {}
          else raise
        end

        route_options = options.dup
        route_options[:provides] = @_provides if @_provides

        if allow_disabled_csrf
          unless route_options[:csrf_protection] == false
            route_options[:csrf_protection] = true
          end
        end

        path, *route_options[:with] = path if path.is_a?(Array)
        action = path
        path, name, route_parents, options, route_options = *parse_route(path, route_options, verb)
        options.reverse_merge!(@_conditions) if @_conditions

        method_name = "#{verb} #{path}"
        unbound_method = generate_method(method_name, &block)

        block = block.arity != 0 ?
          proc {|a,p| unbound_method.bind(a).call(*p) } :
          proc {|a,p| unbound_method.bind(a).call }

        invoke_hook(:route_added, verb, path, block)

        # Pendragon route construction
        path[0, 0] = "/" if path == "(.:format)?"
        route_options.merge!(:name => name) if name
        route = router.add(verb.downcase.to_sym, path, route_options)
        route.action = action
        priority_name = options.delete(:priority) || :normal
        priority = ROUTE_PRIORITY[priority_name] or raise("Priority #{priority_name} not recognized, try #{ROUTE_PRIORITY.keys.join(', ')}")
        route.cache = options.key?(:cache) ? options.delete(:cache) : @_cache
        route.parent = route_parents ? (route_parents.count == 1 ? route_parents.first : route_parents) : route_parents
        route.host = options.delete(:host) if options.key?(:host)
        route.user_agent = options.delete(:agent) if options.key?(:agent)
        if options.key?(:default_values)
          defaults = options.delete(:default_values)
          route.options[:default_values] = defaults if defaults
        end
        options.delete_if do |option, captures|
          if route.significant_variable_names.include?(option)
            route.capture[option] = Array(captures).first
            true
          end
        end

        # Add Sinatra conditions
        options.each {|o, a| route.respond_to?("#{o}=") ? route.send("#{o}=", a) : send(o, *a) }
        conditions, @conditions = @conditions, []
        route.custom_conditions.concat(conditions)

        invoke_hook(:padrino_route_added, route, verb, path, args, options, block)

        # Add Application defaults
        route.before_filters << @filters[:before]
        route.after_filters << @filters[:after]
        if @_controller
          route.use_layout = @layout
          route.controller = Array(@_controller)[0].to_s
        end

        deferred_routes[priority] << [route, block]

        route
      end

      def parse_route(path, options, verb)
        route_options = {}

        # We need check if path is a symbol, if that it's a named route.
        map = options.delete(:map)

        # path i.e :index or :show
        if path.kind_of?(Symbol)
          name = path
          path = map ? map.dup : (path == :index ? '/' : path.to_s)
        end

        # Build our controller
        controller = Array(@_controller).map(&:to_s)

        case path
        when String # path i.e "/index" or "/show"
          # Now we need to parse our 'with' params
          if with_params = options.delete(:with)
            path = process_path_for_with_params(path, with_params)
          end

          # Now we need to parse our provides
          options.delete(:provides) if options[:provides].nil?

          if @_use_format or format_params = options[:provides]
            process_path_for_provides(path, format_params)
            # options[:add_match_with] ||= {}
            # options[:add_match_with][:format] = /[^\.]+/
          end

          absolute_map = map && map[0] == ?/

          unless controller.empty?
            # Now we need to add our controller path only if not mapped directly
            if map.blank? and !absolute_map
              controller_path = controller.join("/")
              path.gsub!(%r{^\(/\)|/\?}, "")
              path = File.join(controller_path, path) unless @_map
            end
          end

          # Now we need to parse our 'parent' params and parent scope.
          if !absolute_map and parent_params = options.delete(:parent) || @_parent
            parent_params = (Array(@_parent) + Array(parent_params)).uniq
            path = process_path_for_parent_params(path, parent_params)
          end

          # Add any controller level map to the front of the path.
          path = "#{@_map}/#{path}".squeeze('/') unless absolute_map or @_map.blank?

          # Small reformats
          path.gsub!(%r{/\?$}, '(/)') # Remove index path
          path.gsub!(%r{//$}, '/') # Remove index path
          path[0,0] = "/" if path !~ %r{^\(?/} # Paths must start with a /
          path.sub!(%r{/(\))?$}, '\\1') if path != "/" # Remove latest trailing delimiter
          path.gsub!(/\/(\(\.|$)/, '\\1') # Remove trailing slashes
          path.squeeze!('/')
        when Regexp
          route_options[:path_for_generation] = options.delete(:generate_with) if options.key?(:generate_with)
        end

        name = options.delete(:route_name) if name.nil? && options.key?(:route_name)
        name = options.delete(:name) if name.nil? && options.key?(:name)
        if name
          controller_name = controller.join("_")
          name = "#{controller_name} #{name}".to_sym unless controller_name.blank?
        end

        # Merge in option defaults.
        options.reverse_merge!(:default_values => @_defaults)

        [path, name, parent_params, options, route_options]
      end

      def provides(*types)
        @_use_format = true
        condition do
          mime_types = types.map {|t| mime_type(t) }.compact
          url_format = params[:format].to_sym if params[:format]
          accepts = request.accept.map {|a| a.to_str }
          accepts = [] if accepts == ["*/*"]

          # per rfc2616-sec14:
          # Assume */* if no ACCEPT header is given.
          catch_all = (accepts.delete "*/*" || accepts.empty?)
          matching_types = accepts.empty? ? mime_types.slice(0,1) : (accepts & mime_types)
          if matching_types.empty? && types.include?(:any)
            matching_types = accepts
          end

          if !url_format && matching_types.first
            type = ::Rack::Mime::MIME_TYPES.find {|k, v| v == matching_types.first }[0].sub(/\./,'').to_sym
            accept_format = CONTENT_TYPE_ALIASES[type] || type
          elsif catch_all && !types.include?(:any)
            type = types.first
            accept_format = CONTENT_TYPE_ALIASES[type] || type
          end

          matched_format = types.include?(:any) ||
                           types.include?(accept_format) ||
                           types.include?(url_format) ||
                           ((!url_format) && request.accept.empty? && types.include?(:html))
          # per rfc2616-sec14:
          # answer with 406 if accept is given but types to not match any
          # provided type
          halt 406 if
            (!url_format && !accepts.empty? && !matched_format) ||
            (settings.respond_to?(:treat_format_as_accept) && settings.treat_format_as_accept && url_format && !matched_format)

          if matched_format
            @_content_type = url_format || accept_format || :html
            content_type(@_content_type, :charset => 'utf-8')
          end

          matched_format
        end
      end

      def process_path_for_parent_params(path, parent_params)
        parent_prefix = parent_params.flatten.compact.uniq.map do |param|
          map = (param.respond_to?(:map) && param.map ? param.map : param.to_s)
          part = "#{map}/:#{param.to_s.singularize}_id/"
          part = "(#{part})?" if param.respond_to?(:optional) && param.optional?
          part
        end

        [parent_prefix, path].flatten.join("")
      end

      def process_path_for_provides(path, format_params)
        path << "(.:format)?" unless path[-11, 11] == '(.:format)?'
      end
    end
  end
end

if defined?(Padrino) && Padrino::VERSION < '0.12.0'
  module Padrino
    class Filter
      def apply?(request)
        detect = @args.any? do |arg|
          case arg
          when Symbol then request.route_obj && (request.route_obj.name == arg or request.route_obj.name == [@scoped_controller, arg].flatten.join(" ").to_sym)
          else arg === request.path_info
          end
        end || @options.any? do |name, val|
          case name
          when :agent then val === request.user_agent
          else val === request.send(name)
          end
        end
        detect ^ !@mode
      end
    end
  end
end
