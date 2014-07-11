require 'pendragon/engine/recognizer'

module Pendragon
  # One of the engine classes for recognizing routes
  # This engine will perform better than the recognizer engine
  #
  # @example
  #   Pendragon.new do |config|
  #     config.enable_compiler = true
  #   end
  #
  # @!visibility private
  class Compiler < Recognizer
    # Concatenates all routes, recognizes routes matched with pattern, and returns them
    # @overload call
    #   @param [Rack::Request] request
    #   @raise [Pendragon::BadRequest] raised if request is bad request
    #   @raise [Pendragon::NotFound] raised if cannot find routes that match with pattern
    #   @raise [Pendragon::MethodNotAllowed] raised if routes can be find and do not match with verb
    #   @return [Array] The return value will be something like [Pendragon::Route, Hash]
    def call(request)
      compile! unless compiled?
      pattern, verb, params = parse_request(request)
      raise_exception(400) unless valid_verb?(verb)
      candidacies = match_with(pattern)
      raise_exception(404) if candidacies.empty?
      candidacies, allows = candidacies.partition{|route| route.verb == verb }
      raise_exception(405, verbs: allows.map(&:verb)) if candidacies.empty?
      candidacies.map{|route| [route, params_for(route, pattern, params)]}
    end

    private

    # @!visibility private
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

    # @!visibility private
    def compile(regexps, paths = [])
      return paths if regexps.length.zero?
      paths << Regexp.union(regexps)
      regexps.shift
      compile(regexps, paths)
    end

    # @!visibility private
    def compiled?
      !!@regexps
    end

    # @!visibility private
    def match_with(pattern)
      offset = 0
      conditions = [pattern]
      conditions << pattern[0..-2] if pattern != Matcher::PATH_DELIMITER && pattern.end_with?(Matcher::PATH_DELIMITER)
      loop.with_object([]) do |_, candidacies|
        return candidacies unless conditions.any?{|x| @regexps[offset] === x }
        route = @routes[offset..-1].detect{|route| Regexp.last_match("_#{route.index}") }
        candidacies << route
        offset = route.index + 1
      end
    end
  end
end
