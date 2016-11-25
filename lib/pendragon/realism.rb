require 'pendragon/router'

module Pendragon
  class Realism < Router
    register :realism

    on :call do |env|
      identity(env) || rotation(env) { |route| route.exec(env) }
    end

    on :compile do |method, routes|
      patterns = routes.map.with_index do |route, index|
        route.index  = index
        route.regexp = /(?<_#{index}>#{route.pattern.to_regexp})/
      end
      omap[method] = Regexp.union(patterns)
    end

    private

    # @!visibility private
    def omap
      @omap ||= Hash.new { |hash, key| hash[key] = // }
    end

    # @!visibility private
    def match?(input, method)
      current_regexp = omap[method]
      return unless current_regexp.match(input)
      last_match = Regexp.last_match
      map[method].detect { |route| last_match["_#{route.index}"] }
    end

    # @!visibility private
    def identity(env, route = nil)
      with_transaction(env) do |input, method|
        route = match?(input, method)
        route.exec(env) if route
      end
    end

    # @!visibility private
    def with_transaction(env)
      input, method = extract(env)
      response = yield(input, method)
      response && !(cascade = cascade?(response)) ? response : nil
    end
  end
end
