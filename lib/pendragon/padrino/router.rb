require 'howl-router' unless defined?(Howl::Router)

module Howl
  module Padrino
    class Router < Howl::Router
      def add(verb, path, options = {}, &block)
        route = Route.new(path, verb, options, &block)
        route.path_for_generation = options[:path_for_generation] if options[:path_for_generation]
        route.router = self
        routes << route
        route
      end

      def call(env)
        request = Rack::Request.new(env)
        raise BadRequest unless valid_verb?(request.request_method)
        prepare! unless prepared?
        [200, {}, recognize(request)]
      rescue BadRequest, NotFound, MethodNotAllowed
        $!.call
      end

      def path(name, *args)
        params = args.delete_at(args.last.is_a?(Hash) ? -1 : 0) || {}
        saved_args = args.dup
        @routes.each do |route|
          next unless route.options[:name] == name
          matcher = route.matcher
          if !args.empty? and matcher.mustermann?
            matcher_names = matcher.names
            params_for_expand = Hash[matcher_names.map{|matcher_name|
              [matcher_name.to_sym, (params[matcher_name.to_sym] || args.shift)]
            }]
            params_for_expand.merge!(Hash[params.select{|k, v| !matcher_names.include?(name.to_sym) }])
            args = saved_args.dup
          else
            params_for_expand = params.dup
          end
          return matcher.mustermann? ? matcher.expand(params_for_expand) : route.path_for_generation
        end
        raise InvalidRouteException
      end
    end
  end
end
