require 'pendragon/route'
require 'pendragon/matcher'
require 'pendragon/error'
require 'pendragon/configuration'
require 'pendragon/engine/compiler'
require 'rack'

module Pendragon
  # A class for the router
  #
  # @example Construct with a block which has no argument
  #   router = Pendragon do
  #     get("/"){ "hello world" }
  #   end
  #
  # @example Construct with a block which has an argument
  #   router = Pendragon.new do |config|
  #     config.enable_compiler = true
  #   end
  class Router
    # The accessors are useful to access from Pendragon::Route
    attr_accessor :current, :routes

    # @see Pendragon::Configuration#lock?
    @@mutex = Mutex.new

    # Constructs a new instance of Pendragon::Router
    # Possible to pass the block
    #
    # @example with a block
    #   app = Pendragon::Router.new do |config|
    #     config.enable_compiler  = true
    #     config.auto_rack_format = false
    #   end
    #
    # @example with base style
    #   app = Pendragon::Router.new
    #   app.get("/"){ "hello!" }
    #   app.post("/"){ "hello post!" }
    def initialize(&block)
      reset!
      if block_given?
        if block.arity.zero?
          instance_eval(&block)
        else
          @configuration = Configuration.new
          block.call(configuration)
        end
      end
    end

    # Finds the routes if request method is valid
    # @return the Rack style response
    def call(env)
      request = Rack::Request.new(env)
      recognize(request).each do |route, params|
        catch(:pass){ return invoke(route, params) }
      end
    rescue BadRequest, NotFound, MethodNotAllowed
      $!.call
    end

    # Calls a route, and build return value of the router
    # @param [Pendragon::Route] route The route matched with the condition of request
    # @param [Hash] params The params will be passed with the route
    # @return [Array<Fixnum, Hash, Array>] The return value of the route block
    def invoke(route, params)
      response = route.arity != 0 ? route.call(params) : route.call
      return response unless configuration.auto_rack_format?
      status = route.options[:status] || 200
      header = {'Content-Type' => 'text/html;charset=utf-8'}.merge(route.options[:header] || {})
      [status, header, Array(response)]
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
      @routes.sort_by!(&:order)
      @engine = (configuration.enable_compiler? ? Compiler : Recognizer).new(routes)
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
      prepare! unless prepared?
      synchronize { @engine.call(request) }
    end

    # Recognizes a given path
    # @param path_info [String]
    # @return [Array]
    def recognize_path(path_info)
      route, params = recognize(Rack::MockRequest.env_for(path_info)).first
      [route.name, params.inject({}){|hash, (key, value)| hash[key.to_sym] = value; hash }]
    end

    # Returns an expanded path matched with the conditions as arguments
    # @return [String, Regexp]
    # @example
    #   router = Pendragon.new
    #   index = router.get("/:id", :name => :index){}
    #   router.path(:index, :id => 1) #=> "/1"
    #   router.path(:index, :id => 2, :foo => "bar") #=> "/1?foo=bar"
    def path(name, *args)
      extract_with(name, *args) do |route, params, matcher|
        matcher.mustermann? ? matcher.expand(params) : route.path
      end
    end

    # Returns Pendragon configuration
    # @return [Pendragon::Configuration]
    def configuration
      @configuration || Pendragon.configuration
    end

    # @!visibility private
    # @example
    #   extract_with(:index) do |route, params|
    #     route.matcher.mustermann? ? route.matcher.expand(params) : route.path
    #   end
    def extract_with(name, *args)
      params = args.delete_at(args.last.is_a?(Hash) ? -1 : 0) || {}
      saved_args = args.dup
      @routes.each do |route|
        next unless route.name == name
        matcher = route.matcher
        if !args.empty? and matcher.mustermann?
          matcher_names = matcher.names
          params_for_expand = Hash[matcher_names.map{|matcher_name|
            [matcher_name.to_sym, (params[matcher_name] || args.shift)]}]
          params_for_expand.merge!(Hash[params.select{|k, v| !matcher_names.include?(name) }])
          args = saved_args.dup
        else
          params_for_expand = params.dup
        end
        return yield(route, params_for_expand, matcher)
      end
      raise InvalidRouteException
    end

    # @!visibility private
    def synchronize(&block)
      if configuration.lock?
        @@mutex.synchronize(&block)
      else
        yield
      end
    end

    private :extract_with
  end
end
