require 'mustermann/sinatra'

module Pendragon
  class Matcher
    # @param [String] path The path is string or regexp.
    # @option options [Hash] :capture Set capture for path pattern.
    # @option options [Hash] :default_values Set default_values for path pattern.
    #
    # @return [Pendragon::Matcher]
    #
    def initialize(path, options = {})
      @path = path.is_a?(String) && path.empty? ? "/" : path
      @capture = options.delete(:capture)
      @default_values = options.delete(:default_values)
    end

    # Do the matching.
    #
    # @param [String] pattern The pattern is actual path (path_info etc).
    #
    # @return [MatchData] If the pattern matched this route, return a MatchData.
    # @return [Nil] If the pattern doesn't matched this route, return a nil.
    #
    def match(pattern)
      pattern = pattern[0..-2] if mustermann? and pattern != "/" and pattern.end_with?("/")
      handler.match(pattern)
    end

    # Expands the path with params.
    #
    # @param [Hash] params The params for path pattern.
    #
    # @example
    # matcher = Pendragon::Matcher.new("/foo/:bar")
    # matcher.expand(:bar => 123) #=> "/foo/123"
    # matcher.expand(:bar => "bar", :baz => "test") #=> "/foo/bar?baz=test"
    #
    # @return [String] A expaneded path.
    def expand(params)
      params = params.dup
      query = params.keys.inject({}) do |result, key|
        result[key] = params.delete(key) if !handler.names.include?(key.to_s)
        result
      end
      params.merge!(@default_values) if @default_values.is_a?(Hash)
      expanded_path = handler.expand(params)
      expanded_path = expanded_path + "?" + query.map{|k,v| "#{k}=#{v}" }.join("&") unless query.empty?
      expanded_path
    end

    # @return [Boolean] This matcher's handler is mustermann ?
    def mustermann?
      handler.instance_of?(Mustermann::Sinatra)
    end

    # @return [Mustermann::Sinatra] Returns a Mustermann::Sinatra when @path is string.
    # @return [Regexp] Returns a regexp when @path is regexp.
    def handler
      @handler ||=
        case @path
        when String
          Mustermann::Sinatra.new(@path, :capture => @capture)
        when Regexp
          /^(?:#{@path})$/
        end
    end

    # @return [String] Returns a converted handler.
    def to_s
      handler.to_s
    end

    # @return [Array] Returns a named captures.
    def names
      handler.names.map(&:to_sym)
    end
  end
end
