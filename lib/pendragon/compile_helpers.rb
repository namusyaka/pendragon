
module Pendragon
  module CompileHelpers
    def compile!
      return if compiled?
      @compiled_regexps = Pendragon::HTTP_VERBS.inject({}){|all, verb| all[verb] = []; all }
      @routes.each_with_index do |route, index|
        regexp = route.matcher.handler
        regexp = regexp.to_regexp if route.matcher.mustermann?
        @compiled_regexps[route.verb] << /(?<_#{index}>#{regexp})/
        route.index = "_#{index}"
      end
      @compiled_regexps.each_pair{|verb, regexps| @compiled_regexps[verb] = /\A#{Regexp.union(regexps)}\Z/ }
    end

    def compiled?
      !!@compiled_regexps
    end

    def recognize_by_compiling_regexp(request)
      path_info, verb, request_params = parse_request(request)

      unless @compiled_regexps[verb] === path_info
        old_path_info = path_info
        path_info = path_info[0..-2] if path_info != "/" and path_info[-1] == "/"
        raise NotFound if old_path_info == path_info || !(@compiled_regexps[verb] === path_info)
      end

      route = @routes.select{|route| route.verb == verb }.detect{|route| Regexp.last_match(route.index) }
      [[route, generate_route_params(route.match(path_info), request_params)]]
    end
  end
end
