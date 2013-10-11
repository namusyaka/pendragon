class Howl
  class Router
    attr_reader :current_order, :routes

    def initialize
      reset!
    end

    def recognize(request)
      path_info, verb, request_params = parse_request(request)
      ignore_slash_path_info = path_info
      ignore_slash_path_info = path_info[0..-2] if path_info != "/" and path_info[-1] == "/"
      matched_routes = scan_routes(path_info, ignore_slash_path_info)
      raise NotFound if matched_routes.empty?
      raise_method_not_allowed(request, matched_routes) unless matched_routes.find{|r|r.verb == verb}
      result = matched_routes.map do |route|
        next unless verb == route.verb
        params, matcher = {}, route.matcher
        match_data = matcher.match(matcher.mustermann? ? ignore_slash_path_info : path_info)
        if match_data.names.empty?
          params[:captures] = match_data.captures
        else
          params.merge!(match_data.names.inject({}){|result, name|
            result[name.to_sym] = match_data[name] ? Rack::Utils.unescape(match_data[name]) : nil
            result
          }).merge!(request_params){|key, self_value, new_value| self_value || new_value }
        end
        [route, params]
      end.compact
      result.empty? ? raise_method_not_allowed(request, matched_routes) : result
    end

    def increment_order
      @current_order += 1
    end

    def compile
      return if @current_order.zero?
      @routes.sort!{|a, b| a.order <=> b.order }
    end

    def reset!
      @routes            = []
      @current_order     = 0
    end

    private

    def scan_routes(path_info, ignore_slash_path_info)
      @routes.select do |route|
        matcher = route.matcher
        matcher.match(matcher.mustermann? ? ignore_slash_path_info : path_info)
      end
    end

    def parse_request(request)
      if request.is_a?(Hash)
        [request['PATH_INFO'], request['REQUEST_METHOD'].downcase.to_sym, {}]
      else
        [request.path_info, request.request_method.downcase.to_sym, parse_request_params(request.params)]
      end
    end

    def parse_request_params(params)
      params.inject({}) do |result, entry|
        result[entry[0].to_sym] = entry[1]
        result
      end
    end

    def raise_method_not_allowed(request, matched_routes)
      request.acceptable_methods = matched_routes.map(&:verb)
      raise MethodNotAllowed
    end
  end
end
