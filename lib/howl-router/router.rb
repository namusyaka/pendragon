class Howl
  class Router
    attr_reader :current_order, :routes, :routes_with_verbs

    def initialize
      reset!
    end

    def recognize(request)
      path_info, verb, request_params = request.is_a?(Hash) ? [request['PATH_INFO'], request['REQUEST_METHOD'], {}] :
                                                              [request.path_info, request.request_method, request.params]
      verb = verb.downcase.to_sym
      ignore_slash_path_info = path_info
      ignore_slash_path_info = path_info[0..-2] if path_info != "/" and path_info[-1] == "/"

      # Convert hash key into symbol.
      request_params = request_params.inject({}) do |result, entry|
        result[entry[0].to_sym] = entry[1]
        result
      end

      all_matched_routes = @routes.select do |route|
        matcher = route.matcher
        matcher.match(matcher.mustermann? ? ignore_slash_path_info : path_info)
      end
      raise NotFound if all_matched_routes.empty? 

      raise_method_not_allowed(request, all_matched_routes) unless routes_with_verbs.has_key?(verb)
      result = all_matched_routes.map{|route|
        next unless verb == route.verb
        params, matcher = {}, route.matcher
        match_data = matcher.match(matcher.mustermann? ? ignore_slash_path_info : path_info)
        if match_data.names.empty?
          params[:captures] = match_data.captures
        else
          params.merge!(route.params).merge!(match_data.names.inject({}){|result, name|
            result[name.to_sym] = match_data[name] ? Rack::Utils.unescape(match_data[name]) : nil
            result
          }).merge!(request_params){|key, self_value, new_value| self_value || new_value }
        end
        [route, params]
      }.compact
      raise_method_not_allowed(request, all_matched_routes) if result.empty?
      result
    end

    def increment_order
      @current_order += 1
    end

    def compile
      return if @current_order.zero?
      @routes_with_verbs.each_value{|routes_with_verb|
        routes_with_verb.sort!{|a, b| a.order <=> b.order }
      }
      @routes.sort!{|a, b| a.order <=> b.order }
    end

    def reset!
      @routes            = []
      @routes_with_verbs = {}
      @current_order     = 0
    end

    def raise_method_not_allowed(request, matched_routes)
      request.acceptable_methods = matched_routes.map(&:verb)
      raise MethodNotAllowed
    end
  end
end
