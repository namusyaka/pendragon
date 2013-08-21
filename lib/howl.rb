require 'rack'

%w[
  route
  router
  matcher
  request
].each{|name| require File.expand_path("../howl/#{name}", __FILE__) }


class Howl
  class InvalidRouteException < ArgumentError
  end

  attr_accessor :request, :response

  HTTP_VERBS       = [:get, :post, :delete, :put, :head]
  RESPONSE_HEADERS = {
    :bad_request        => 400,
    :not_found          => 404,
    :method_not_allowed => 405,
    :server_error       => 500
  }

  def add(verb, path, options = {}, &block)
    verb = verb.downcase.to_sym
    (router.routes_with_verbs[verb] ||= []) << (route = Route.new(path, &block))
    route.path_for_generation = options[:path_for_generation] if options[:path_for_generation]
    route.verb = verb
    route.router = router
    router.routes << route
    route
  end

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

  def compiled?
    @compiled
  end

  def compile
    @compiled = true
    router.compile
  end

  def recognize(request)
    router.recognize(request)
  end

  def recognize_path(path_info)
    response      = router.recognize(Rack::MockRequest.env_for(path_info))
    route, params = response.first
    [route.name, params]
  end

  def reset!
    @router = @compiled = nil
    router.reset!
  end

  def router
    @router ||= Router.new
  end

  def routes
    router.routes
  end

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
    [RESPONSE_HEADERS[key], headers, [key.to_s.split('_').map(&:capitalize) * " "]]
  end
end
