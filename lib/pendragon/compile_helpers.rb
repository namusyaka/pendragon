
module Pendragon
  module CompileHelpers
    def compile!
      return if compiled?
      @regexps = @routes.map.with_index do |route, index|
        regexp = route.matcher.handler
        regexp = regexp.to_regexp if route.matcher.mustermann?
        route.index = index
        /(?<_#{index}>#{regexp})/
      end
      @regexps = compile(@regexps)
    end

    def compile(regexps, paths = [])
      return paths if regexps.length.zero?
      paths << Regexp.union(regexps)
      regexps.shift
      compile(regexps, paths)
    end

    def compiled?
      !!@regexps
    end

    def recognize_by_compiling_regexp(request)
      pattern, verb, params = parse_request(request)
      candidacies = match_with(pattern)
      raise_exception(404) if candidacies.empty?
      candidacies.reject!{|route| route.verb != verb }
      raise_exception(405) if candidacies.empty?
      candidacies.map{|route| [route, params_for(route, pattern, params)]}
    end

    def match_with(pattern)
      offset = 0
      conditions = [pattern]
      conditions << pattern[0..-2] if pattern != "/" && pattern.end_with?("/")
      loop.with_object([]) do |_, candidacies|
        return candidacies unless conditions.any?{|x| @regexps[offset] === x }
        route = @routes[offset..-1].detect{|route| Regexp.last_match("_#{route.index}") }
        candidacies << route
        offset = route.index + 1
      end
    end
  end
end
