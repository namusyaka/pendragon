class Howl
  class Route
    attr_accessor :block, :capture, :router, :name,
                  :order, :default_values, :verb

    # @param [String, Regexp] path The path associate to this route.
    # @yield The block associate to this route.
    #
    # @example
    #
    #   howl  = Howl.new
    #   index = howl.add(:get "/") # returns Howl::Route
    #   index.name = :index # Naming
    #   index.verb = :get # Define a http verb.
    #
    def initialize(path, &block)
      @path     = path
      @capture  = {}
      @order    = 0
      @block    = block if block_given?
    end

    # Return a matcher which is wrapper of Mustermann or Regexp.
    #
    # @return [Howl::Matcher]
    #
    def matcher
      @matcher ||= Matcher.new(@path, :capture        => @capture,
                                      :default_values => @default_values)
    end

    # Return a block's arity.
    #
    # @return [Fixnum]
    #
    def arity
      @block.arity
    end

    def call(*args)
      @block.call(*args)
    end

    # Add a block later, and this method define a priority for routing.
    #
    # @yield The block associate to this route later.
    #
    def to(&block)
      @block = block if block_given?
      @order = @router.current_order
      @router.increment_order
    end

    # Return a set path.
    #
    # @param [Hash] args[0] The hash for route's params.
    #
    # @example
    #
    #   howl = Howl.new
    #   foo  = howl.add(:get, "/foo/:id")
    #   foo.path #=> "/foo/:id"
    #   foo.path(:id => 1) #=> "/foo/1"
    #
    # @return [String] path pattern or expanded path.
    #
    def path(*args)
      return @path if args.empty?
      params = args[0]
      params.delete(:captures)
      matcher.expand(params) if matcher.mustermann?
    end
  end
end
