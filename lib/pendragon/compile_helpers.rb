
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
      pattern, verb, params = parse_request(request)
      unless @compiled_regexps[verb] === pattern
        old_pattern = pattern
        pattern = pattern[0..-2] if pattern != "/" and pattern.end_with?("/")
        raise NotFound if old_pattern == pattern || !(@compiled_regexps[verb] === pattern)
      end
      route = @routes.select{|route| route.verb == verb }.detect{|route| Regexp.last_match(route.index) }
      [[route, params_for(route, pattern, params)]]
    end
  end
end
