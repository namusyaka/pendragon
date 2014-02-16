require 'pendragon/route'
require 'pendragon/matcher'
require 'pendragon/error_handler'
require 'pendragon/compile_helpers'
require 'pendragon/configuration'
require 'rack'

module Pendragon
  class Router

    # The accessors are useful to access from Pendragon::Route
    attr_accessor :current, :routes

    # Constructs a new instance of Pendragon::Router
    # Possible to pass the block
    #
    # @example with a block
    #   app = Pendragon::Router.new do
    #     get("/"){ "hello!" }
    #     post("/"){ "hello post!" }
    #   end
    #
    # @example with base style
    #   app = Pendragon::Router.new
    #   app.get("/"){ "hello!" }
    #   app.post("/"){ "hello post!" }
    def initialize(&block)
      reset!
      instance_eval(&block) if block_given?
    end

    # Finds the routes if request method is valid
    # @return the Rack style response
    def call(env)
      request = Rack::Request.new(env)
      raise BadRequest unless valid_verb?(request.request_method)
      prepare! unless prepared?
      route, params = recognize(request).first
      body = route.arity != 0 ? route.call(params) : route.call
      [200, {'Content-Type' => 'text/html;charset=utf-8'}, Array(body)]
    rescue BadRequest, NotFound, MethodNotAllowed
      $!.call
    end

    # Provides some methods intuitive than #add
    # Basic usage is the same as #add
    # @see Pendragon::Router#add
    def get(path, options = {}, &block);    add :get,    path, options, &block end
    def post(path, options = {}, &block);   add :post,   path, options, &block end
    def delete(path, options = {}, &block); add :delete, path, options, &block end
    def put(path, options = {}, &block);    add :put,    path, options, &block end
    def head(path, options = {}, &block);   add :head,   path, options, &block end

    # Adds a new route to router
    # @return [Pendragon::Route]
    def add(verb, path, options = {}, &block)
      routes << (route = Route.new(path, verb, options, &block))
      route.router = self
      route
    end

    # Resets the router's instance variables
    def reset!
      @routes = []
      @current = 0
      @prepared = nil
    end

    # Prepares the router for route's priority
    # This method is executed only once in the initial load
    def prepare!
      @prepared = true
      @routes.sort_by!(&:order) unless current.zero?
      if Pendragon.configuration.enable_compiler?
        class << self
          include CompileHelpers
          alias_method :old_recognize, :recognize
          alias_method :recognize, :recognize_by_compiling_regexp
        end
        compile!
      end
    end

    # @return [Boolean] the router is already prepared?
    def prepared?
      !!@prepared
    end

    # Increments for the integrity of priorities
    def increment_order!
      @current += 1
    end

    # Recognizes the route by request
    # @param request [Rack::Request]
    # @return [Array]
    def recognize(request)
      path_info, verb, request_params = parse_request(request)
      scan(path_info, verb) do |route|
        [route, generate_route_params(route.match(path_info), request_params)]
      end
    end

    # Recognizes a given path
    # @param path_info [String]
    # @return [Array]
    def recognize_path(path_info)
      route, params = recognize(Rack::MockRequest.env_for(path_info)).first
      [route.options[:name], params]
    end

    # Returns a expanded path matched with the conditions as arguments
    # @return [String, Regexp]
    # @example
    #   router = Pendragon.new
    #   index = router.get("/:id", :name => :index){}
    #   router.path(:index, :id => 1) #=> "/1"
    #   router.path(:index, :id => 2, :foo => "bar") #=> "/1?foo=bar"
    def path(name, *args)
      params = args.delete_at(args.last.is_a?(Hash) ? -1 : 0) || {}
      saved_args = args.dup
      @routes.each do |route|
        next unless route.options[:name] == name
        matcher = route.matcher
        if !args.empty? and matcher.mustermann?
          matcher_names = matcher.names
          params_for_expand = Hash[matcher_names.map{|matcher_name|
            [matcher_name.to_sym, (params[matcher_name.to_sym] || args.shift)]}]
          params_for_expand.merge!(Hash[params.select{|k, v| !matcher_names.include?(name.to_sym) }])
          args = saved_args.dup
        else
          params_for_expand = params.dup
        end
        return matcher.mustermann? ? matcher.expand(params_for_expand) : route.path
      end
      raise InvalidRouteException
    end

    private

    # @!visibility private
    def valid_verb?(verb)
      Pendragon::HTTP_VERBS.include?(verb.downcase.to_sym)
    end

    # @!visibility private
    def scan(pattern, verb)
      raise NotFound if (selected_routes = routes.select{|route| route.match(pattern) }).empty?

      result = selected_routes.map do |route|
        next unless verb == route.verb
        yield route
      end.compact

      if result.empty?
        raise MethodNotAllowed.new(selected_routes.map(&:verb))
      else
        result
      end
    end

    # @!visibility private
    def parse_request(request)
      if request.is_a?(Hash)
        [request['PATH_INFO'], request['REQUEST_METHOD'].downcase.to_sym, {}]
      else
        [request.path_info, request.request_method.downcase.to_sym, parse_request_params(request.params)]
      end
    end

    # @!visibility private
    def parse_request_params(params)
      params.inject({}) do |result, entry|
        result[entry[0].to_sym] = entry[1]
        result
      end
    end

    # @!visibility private
    def generate_route_params(match_data, default_params)
      params = {}
      if match_data.names.empty?
        params[:captures] = match_data.captures
      else
        params.merge!(match_data.names.inject({}){|result, name|
          result[name.to_sym] = match_data[name] ? Rack::Utils.unescape(match_data[name]) : nil
          result
        }).merge!(default_params){|key, self_val, new_val| self_val || new_val }
      end
      params
    end
  end
end
