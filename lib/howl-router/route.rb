class Howl
  class Route
    attr_accessor :block, :capture, :router, :params, :name,
                  :order, :default_values, :path_for_generation, :verb

    def initialize(path, &block)
      @path     = path
      @params   = {}
      @capture  = {}
      @order    = 0
      @block    = block if block_given?
    end

    def matcher
      @matcher ||= Matcher.new(@path, :capture        => @capture,
                                      :default_values => @default_values)
    end

    def arity
      @block.arity
    end

    def call(*args)
      @block.call(*args)
    end

    def to(&block)
      @block = block if block_given?
      @order = @router.current_order
      @router.increment_order
    end

    def path(*args)
      return @path if args.empty?
      params = args[0]
      params.delete(:captures)
      matcher.expand(params) if matcher.mustermann?
    end
  end
end
