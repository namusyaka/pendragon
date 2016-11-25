require 'pendragon/constants'
require 'pendragon/errors'
require 'mustermann'
require 'forwardable'
require 'ostruct'

module Pendragon
  class Router
    # @!visibility private
    attr_accessor :prefix

    # Registers new router type onto global maps.
    #
    # @example registring new router type.
    #   require 'pendragon'
    #
    #   class Pendragon::SuperFast < Pendragon::Router
    #     register :super_fast
    #   end
    #
    #   Pendragon[:super_fast] #=> Pendragon::SuperFast
    #
    # @param [Symbol] name a router type identifier
    # @see Pendragon.register
    def self.register(name)
      Pendragon.register(name, self)
    end

    # Adds event listener in router class.
    #
    # @example
    #   require 'pendragon'
    #
    #   class Pendragon::SuperFast < Pendragon::Router
    #     register :super_fast
    #
    #     on :call do |env|
    #       rotation(env) { |route| route.exec(env) }
    #     end
    #
    #     on :compile do |method, routes|
    #       routes.each do |route|
    #         route.pattern = route.pattern.to_regexp
    #       end
    #     end
    #   end
    #
    # @param [Symbol] event a event name which is :call or :compile
    #
    # @yieldparam [optional, Hash] env a request environment variables on :call event.
    # @yieldreturn [optional, Array<Integer, Hash, #each>, Rack::Response] response
    #
    # @yieldparam [String] method
    # @yieldparam [Array<Pendragon::Route>] routes
    def self.on(event, &listener)
      define_method('on_%s_listener' % event, &listener)
    end

    # Construcsts an instance of router class.
    #
    # @example construction for router class
    #   require 'pendragon'
    #
    #   Pendragon.new do
    #     get '/', to: -> { [200, {}, ['hello']] }
    #   end
    #
    # @yield block a block is evaluated in instance context.
    # @return [Pendragon::Router]
    def initialize(&block)
      instance_eval(&block) if block_given?
    end

    # Prefixes a namespace to route path inside given block.
    #
    # @example
    #   require 'pendragon'
    #
    #   Pendragon.new do
    #     namespace :foo do
    #       # This definition is dispatched to '/foo/bar'.
    #       get '/bar', to: -> { [200, {}, ['hello']] }
    #     end
    #   end
    # 
    # @yield block a block is evaluated in instance context.
    def namespace(name, &block)
      fail ArgumentError unless block_given?
      (self.prefix ||= []) << name.to_s
      instance_eval(&block)
    ensure
      prefix.pop
    end

    # Calls by given env, returns a response conformed Rack style.
    #
    # @example
    #   require 'pendragon'
    #
    #   router = Pendragon.new do
    #     get '/', to: -> { [200, {}, ['hello']]  }
    #   end
    #
    #   env = Rack::MockRequest.env_for('/')
    #   router.call(env) #=> [200, {}, ['hello']]
    #
    # @return [Array<Integer, Hash, #each>, Rack::Response] response conformed Rack style
    def call(env)
      catch(:halt) { with_optimization { invoke(env) } }
    end

    # Class for delegation based structure.
    # @!visibility private
    class Route < OpenStruct
      # @!visibility private
      attr_accessor :pattern

      # @!visibility private
      attr_reader :request_method, :path

      extend Forwardable
      def_delegators :@pattern, :match, :params

      # @!visibility private
      def initialize(method:, pattern:, application:, **attributes)
        super(attributes)

        @app            = application
        @path           = pattern
        @pattern        = Mustermann.new(pattern)
        @executable     = to_executable
        @request_method = method.to_s.upcase
      end

      # @!visibility private
      def exec(env)
        return @app.call(env) unless executable?
        path_info = env[Constants::Env::PATH_INFO]
        params = pattern.params(path_info)
        captures = pattern.match(path_info).captures
        Context.new(env, params: params, captures: captures).trigger(@executable)
      end

      private

      # @!visibility private
      def executable?
        @app.kind_of?(Proc)
      end

      # @!visibility private
      def to_executable
        return @app unless executable?
        Context.to_method(request_method, path, @app)
      end

      # Class for providing helpers like :env, :params and :captures.
      # This class will be available if given application is an kind of Proc.
      # @!visibility private
      class Context
        # @!visibility private
        attr_reader :env, :params, :captures

        # @!visibility private
        def self.generate_method(name, callable)
          define_method(name, &callable)
          method = instance_method(name)
          remove_method(name)
          method
        end

        # @!visibility private
        def self.to_method(*args, callable)
          unbound = generate_method(args.join(' '), callable)
          if unbound.arity.zero?
            proc { |app, captures| unbound.bind(app).call }
          else
            proc { |app, captures| unbound.bind(app).call(*captures) }
          end
        end

        # @!visibility private
        def initialize(env, params: {}, captures: [])
          @env = env
          @params = params
          @captures = captures
        end

        # @!visibility private
        def trigger(executable)
          executable[self, captures]
        end
      end
    end

    # Appends a route of GET method
    # @see [Pendragon::Router#route]
    def get(path, to: nil, **options, &block)
      route Constants::Http::GET, path, to: to, **options, &block
    end

    # Appends a route of POST method
    # @see [Pendragon::Router#route]
    def post(path, to: nil, **options, &block)
      route Constants::Http::POST, path, to: to, **options, &block
    end

    # Appends a route of PUT method
    # @see [Pendragon::Router#route]
    def put(path, to: nil, **options, &block)
      route Constants::Http::PUT, path, to: to, **options, &block
    end

    # Appends a route of DELETE method
    # @see [Pendragon::Router#route]
    def delete(path, to: nil, **options, &block)
      route Constants::Http::DELETE, path, to: to, **options, &block
    end

    # Appends a route of HEAD method
    # @see [Pendragon::Router#route]
    def head(path, to: nil, **options, &block)
      route Constants::Http::HEAD, path, to: to, **options, &block
    end

    # Appends a route of OPTIONS method
    # @see [Pendragon::Router#route]
    def options(path, to: nil, **options, &block)
      route Constants::Http::OPTIONS, path, to: to, **options, &block
    end

    # Appends a new route to router.
    #
    # @param [String] method A request method, it should be upcased.
    # @param [String] path The application is dispatched to given path.
    # @option [Class, #call] :to
    def route(method, path, to: nil, **options, &block)
      app = block_given? ? block : to
      fail ArgumentError, 'Rack application could not be found' unless app
      path = ?/ + prefix.join(?/) + path if prefix && !prefix.empty?
      append Route.new(method: method, pattern: path, application: app, **options)
    end

    # Maps all routes for each request methods.
    # @return [Hash{String => Array}] map
    def map
      @map ||= Hash.new { |hash, key| hash[key] = [] }
    end

    # Maps all routes.
    # @return [Array<Pendragon::Route>] flat_map
    def flat_map
      @flat_map ||= []
    end

    private

    # @!visibility private
    def append(route)
      flat_map << route
      map[route.request_method] << route
    end

    # @!visibility private
    def invoke(env)
      response = on_call_listener(env)
      if !response && (allows = find_allows(env))
        error!(Errors::MethodNotAllowed, allows: allows)
      end
      response || error!(Errors::NotFound)
    end

    # @!visibility private
    def error!(error_class, **payload)
      throw :halt, error_class.new(**payload).to_response
    end

    # @!visibility private
    def find_allows(env)
      pattern = env[Constants::Env::PATH_INFO]
      hits = flat_map.select { |route| route.match(pattern) }.map(&:request_method)
      hits.empty? ? nil : hits
    end

    # @!visibility private
    def extract(env, required: [:input, :method])
      extracted = []
      extracted << env[Constants::Env::PATH_INFO] if required.include?(:input)
      extracted << env[Constants::Env::REQUEST_METHOD] if required.include?(:method)
      extracted
    end

    # @!visibility private
    def rotation(env, exact_route = nil)
      input, method = extract(env)
      response = nil
      map[method].each do |route|
        next unless route.match(input)
        response = yield(route)
        break(response) unless cascade?(response)
        response = nil
      end
      response
    end

    # @!visibility private
    def cascade?(response)
      response && response[1][Constants::Header::CASCADE] == 'pass'
    end

    # @!visibility private
    def compile
      map.each(&method(:on_compile_listener))
      @compiled = true
    end

    # @!visibility private
    def with_optimization
      compile unless compiled?
      yield
    end

    # Optional event listener
    # @param [String] method A request method like GET, POST
    # @param [Array<Pendragon::Route>] routes All routes associated to the method
    # @!visibility private
    def on_compile_listener(method, routes)
    end

    # @!visibility private
    def on_call_listener(env)
      fail NotImplementedError
    end

    # @!visibility private
    def compiled?
      @compiled
    end
  end
end
