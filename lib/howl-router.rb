require 'rack'
require 'howl-router/route'
require 'howl-router/router'
require 'howl-router/matcher'
require 'howl-router/request'

class Howl
  class InvalidRouteException < ArgumentError
  end

  HTTP_VERBS       = [:get, :post, :delete, :put, :head]
  RESPONSE_HEADERS = {
    :bad_request        => 400,
    :not_found          => 404,
    :method_not_allowed => 405,
    :server_error       => 500
  }

  def initialize(&block)
    instance_eval(&block) if block_given?
  end

  # Generate a route, and add to routes.
  #
  # @param [String, Symbol] verb The verb decide a acceptable request method.
  # @param [String, Regexp] path The path associate to route.
  # @option options [String] :path_for_generation Accept path_for_generation.
  # @yield The block associate to route.
  #
  # @example
  #   howl = Howl.new
  #   howl.add(:get, "/") #=> Howl::Route
  #
  # @return [Howl::Route] Return a generated Howl::Route instance.
  #
  def add(verb, path, options = {}, &block)
    verb = verb.downcase.to_sym
    (router.routes_with_verbs[verb] ||= []) << (route = Route.new(path, &block))
    route.path_for_generation = options[:path_for_generation] if options[:path_for_generation]
    route.verb = verb
    route.router = router
    router.routes << route
    route
  end

  # call method for Rack Application.
  def call(env)
    request  = Request.new(env)
    return bad_request unless HTTP_VERBS.include?(request.request_method.downcase.to_sym)
    compile unless compiled?
    begin
      matched_routes = recognize(request)
      route, params = matched_routes.first
      result = route.arity != 0 ? route.call(params) : route.call
      [200, {'Content-Type' => 'text/html;charset=utf-8;'}, [result]]
    rescue => evar
      case evar
      when NotFound then not_found
      when MethodNotAllowed then method_not_allowed
      else server_error
      end
    end
  end

  # Determines whether the compiled.
  #
  # @return [Boolean]
  #
  def compiled?
    @compiled
  end

  # Compile routes.
  #
  # @return [Array] Return a compiled routes.
  #
  def compile
    @compiled = true
    router.compile
  end

  # Recognize a request, and return a matched routes.
  #
  # @param [Rack::Request] request The request is a Rack::Request or instance that inherited it.
  #
  # @return [Array] Return a routes that match the path_info.
  #
  def recognize(request)
    router.recognize(request)
  end

  # Recognize a path_info, and return a matched first route's name and params.
  #
  # @param [String] path_info
  #
  # @return [Array] Return an Array that likes [name, params].
  def recognize_path(path_info)
    response      = router.recognize(Rack::MockRequest.env_for(path_info))
    route, params = response.first
    [route.name, params]
  end

  # Reset a router.
  def reset!
    @compiled = nil
    router.reset!
  end

  # Return a Router instance.
  #
  # @return [Howl::Router]
  #
  def router
    @router ||= Router.new
  end

  # Return a added routes.
  #
  # @return [Array]
  #
  def routes
    router.routes
  end

  # Find a route, and return a generated path of route.
  #
  # @param [Symbol] name The name is route name.
  # @param [Array] args The args are route params and queries.
  #
  # @example
  #
  #   howl = Howl.new
  #   index = howl.add(:get, "/:id"){}
  #   index.name = :index
  #   howl.path(:index, :id => 1) #=> "/1"
  #   howl.path(:index, :id => 2, :foo => "bar") #=> "/1?foo=bar"
  #
  # @return [String] return a generated path.
  #
  def path(name, *args)
    params = args.delete_at(args.last.is_a?(Hash) ? -1 : 0) || {}
    saved_args = args.dup
    router.routes.each do |route|
      next unless route.name == name
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

  RESPONSE_HEADERS.keys.each do |method_name|
    define_method(method_name){|headers = {}| generate_response(method_name.to_sym, headers) }
    Object.const_set(method_name.to_s.split('_').map(&:capitalize).join, Class.new(StandardError))
  end

  private

  def generate_response(key, headers = {})
    headers['Content-Type'] = 'text/html;charset=utf-8;' if headers.empty?
    [RESPONSE_HEADERS[key], headers, [key.to_s.split('_').map(&:capitalize).join(" ")]]
  end
end
