module Pendragon
  # One of the engine classes for recognizing routes
  # @!visibility private
  class Recognizer
    # The keys for rack headers
    PATH_INFO      = "PATH_INFO".freeze
    REQUEST_METHOD = "REQUEST_METHOD".freeze

    # Constructs an instance of Pendragon::Recognizer
    # @param [Array<Pendragon::Route>] routes
    def initialize(routes)
      @routes = routes
    end

    # Recognized routes, and returns them
    # @param [Rack::Request] request
    # @raise [Pendragon::BadRequest] raised if request is bad request
    # @raise [Pendragon::NotFound] raised if cannot find routes that match with pattern
    # @raise [Pendragon::MethodNotAllowed] raised if routes can be find and do not match with verb
    # @return [Array] The return value will be something like [Pendragon::Route, Hash]
    def call(request)
      pattern, verb, params = parse_request(request)
      raise_exception(400) unless valid_verb?(verb)
      fetch(pattern, verb){|route| [route, params_for(route, pattern, params)] }
    end

    # @!visibility private
    def params_for(route, pattern, params)
      route.params(pattern, params)
    end

    # @!visibility private
    def valid_verb?(verb)
      Pendragon::HTTP_VERBS.include?(verb)
    end

    # @!visibility private
    def fetch(pattern, verb)
      _routes = @routes.select{|route| route.match(pattern) }
      raise_exception(404) if _routes.empty?
      result = _routes.map{|route| yield(route) if verb == route.verb }.compact
      raise_exception(405, :verbs => _routes.map(&:verb)) if result.empty?
      result
    end

    # @!visibility private
    def parse_request(request)
      if request.is_a?(Hash)
        [request[PATH_INFO], request[REQUEST_METHOD].upcase, {}]
      else
        [request.path_info, request.request_method.upcase, request.params]
      end
    end

    # @!visibility private
    def raise_exception(error_code, options = {})
      raise ->(error_code) {
        case error_code
        when 400
          BadRequest
        when 404
          NotFound
        when 405
          MethodNotAllowed.new(options[:verbs])
        end
      }.(error_code)
    end

    private :params_for, :valid_verb?, :fetch, :parse_request, :raise_exception
  end
end
