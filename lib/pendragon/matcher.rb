require 'mustermann/sinatra'

module Pendragon
  # A class for path matching
  #
  # @example
  #   matcher = Pendragon::Matcher.new("/category/:id", capture: {id: /\d+/})
  #   matcher.match("/category/1234") #=> #<MatchData "/category/1234" id:"1234">
  #
  # @!visibility private
  class Matcher
    # A character of path delimiter
    PATH_DELIMITER  = "/".freeze

    # A prefix character of query string
    QUERY_PREFIX    = "?".freeze

    # A character of query string delimiter
    QUERY_DELIMITER = "&".freeze

    # Constructs a new instance of Pendragon::Matcher
    # @param [String] path The path is string or regexp.
    # @option options [Hash] :capture Set capture for path pattern.
    # @option options [Hash] :default_values Set default_values for path pattern.
    # @return [Pendragon::Matcher]
    def initialize(path, options = {})
      @path = path.is_a?(String) && path.empty? ? PATH_DELIMITER : path
      @capture = options.delete(:capture)
      @default_values = options.delete(:default_values)
    end

    # Does the matching.
    # @param [String] pattern The pattern is actual path (path_info etc).
    # @return [MatchData] If the pattern matched this route, return a MatchData.
    # @return [Nil] If the pattern doesn't matched this route, return a nil.
    def match(pattern)
      pattern = pattern[0..-2] if mustermann? and pattern != PATH_DELIMITER and pattern.end_with?(PATH_DELIMITER)
      handler.match(pattern)
    end

    # Expands a path with params.
    # @param [Hash] params The params for path pattern.
    # @example
    #   matcher = Pendragon::Matcher.new("/foo/:bar")
    #   matcher.expand(:bar => 123) #=> "/foo/123"
    #   matcher.expand(:bar => "bar", :baz => "test") #=> "/foo/bar?baz=test"
    # @return [String] A expaneded path.
    def expand(params)
      params = params.dup
      query = params.keys.inject({}) do |result, key|
        result[key] = params.delete(key) if !handler.names.include?(key.to_s)
        result
      end
      params.merge!(@default_values) if @default_values.is_a?(Hash)
      expanded_path = handler.expand(params)
      expanded_path = expanded_path + QUERY_PREFIX + query.map{|k,v| "#{k}=#{v}" }.join(QUERY_DELIMITER) unless query.empty?
      expanded_path
    end

    # Returns whether the handler is Mustermann
    # @return [Boolean] This matcher's handler is mustermann ?
    def mustermann?
      handler.instance_of?(Mustermann::Sinatra)
    end

    # Returns the handler
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

    # Converts the handler into String
    # @return [String] Returns a converted handler.
    def to_s
      handler.to_s
    end

    # Returns all named captures
    # @return [Array] Returns a named captures.
    def names
      handler.names
    end
  end
end
