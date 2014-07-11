module Pendragon
  # A class for defining the route
  #
  # @example
  #   route = Pendragon::Route.new("/:id", "GET", capture: id: /\d+/){|params| params[:id].to_s  }
  #   route.match("/1234") #=> #<MatchData "/category/1234" id:"1234">
  #   route.arity
  class Route

    # The accessors are useful to access from Pendragon::Router
    attr_accessor :name, :capture, :order, :options

    # For compile option
    attr_accessor :index

    # The verb should be read from Pendragon::Router
    attr_reader :verb, :block

    # The router will be treated in this class.
    attr_writer :router

    # Constructs a new instance of Pendragon::Route
    # @param [String, Regexp] path The path of route
    # @param [String, Symbol] verb The verb of route
    # @param [Hash] options The options hash
    def initialize(path, verb, options = {}, &block)
      @block = block if block_given?
      @path, @verb = path, verb.to_s.upcase
      @capture = {}
      @order = 0
      merge_with_options!(options)
    end

    # Returns an instance of Pendragon::Matcherthat is associated with the route
    # @return [Pendragon::Matcher]
    def matcher
      @matcher ||= Matcher.new(@path, :capture        => @capture,
                                      :default_values => options[:default_values])
    end

    # Returns arity of route block
    # @return [Fixnum]
    def arity
      @block.arity
    end

    # Calls the route block with arguments
    # @param [Array] args The arguments are passed to the route block
    def call(*args)
      @block.call(*args)
    end

    # Matches a pattern with the route matcher
    # @param [String] pattern The pattern will be matched with route matcher
    # @return (see Pendragon::Matcher#match)
    def match(pattern)
      matcher.match(pattern)
    end

    # Associates the block with the route, and increments current order of the router
    # @yield The route block
    def to(&block)
      @block = block if block_given?
      @order = @router.current
      @router.increment_order!
    end

    # Expands a path using parameters
    # @param [Array] args
    # @example
    #   pendragon = Pendragon.new
    #   route = pendragon.get("/category/:name"){}
    #   route.path(name: "Doraemon") #=> "/category/Doraemon"
    #   route.path(name: "Doraemon", hey: "Hey") #=> "/category/Doraemon?hey=Hey"
    # @return [String] The expanded path
    def path(*args)
      return @path if args.empty?
      params = args[0]
      params.delete(:captures)
      matcher.expand(params) if matcher.mustermann?
    end

    # Matches a pattern with the route matcher, and then returns the route params
    # @param [String] pattern The pattern will be matched with the matcher
    # @param [Hash] parameters The parameters are base of the route params
    # @example
    #   pendragon = Pendragon.new
    #   route = pendragon.get("/category/:name"){}
    #   route.params("/category/Doraemon") #=> {:name=>"Doraemon"}
    #   route.params("/category/Doraemon", hey: "Hey") #=> {:name=>"Doraemon", :hey=>"Hey"}
    # @return [Hash] The params for use in routing engines
    def params(pattern, parameters = {})
      match_data, params = match(pattern), indifferent_hash
      if match_data.names.empty?
        params.merge!(:captures => match_data.captures) unless match_data.captures.empty?
        params
      else
        params_from_matcher = matcher.handler.params(pattern, :captures => match_data)
        params.merge!(params_from_matcher) if params_from_matcher
        params.merge(parameters){|key, old, new| old || new }
      end
    end

    # @!visibility private
    def merge_with_options!(options)
      @options = {} unless @options
      options.each_pair do |key, value|
        accessor?(key) ? __send__("#{key}=", value) : (@options[key] = value)
      end
    end

    # @!visibility private
    def accessor?(key)
      respond_to?("#{key}=") && respond_to?(key)
    end

    # @!visibility private
    def indifferent_hash
      Hash.new{|hash, key| hash[key.to_s] if key.instance_of?(Symbol) }
    end

    private :merge_with_options!, :accessor?, :indifferent_hash
  end
end
