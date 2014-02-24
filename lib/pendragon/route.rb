module Pendragon
  class Route

    ##
    # The accessors are useful to access from Pendragon::Router
    attr_accessor :block, :capture, :router, :options, :verb, :order

    ##
    # For compile option
    attr_accessor :index

    ##
    # Constructs a new instance of Pendragon::Route
    def initialize(path, verb, options = {}, &block)
      @block = block if block_given?
      @path, @verb, @options = path, verb, options
      @capture = {}
      @order = 0
    end

    def matcher
      @matcher ||= Matcher.new(@path, :capture        => @capture,
                                      :default_values => options[:default_values])
    end

    def arity
      block.arity
    end

    def call(*args)
      @block.call(*args)
    end

    def match(pattern)
      matcher.match(pattern)
    end

    def name
      @options[:name]
    end

    def name=(value)
      warn "[DEPRECATION] 'name=' is depreacted. Please use 'options[:name]=' instead"
      @options[:name] = value
    end

    def to(&block)
      @block = block if block_given?
      @order = router.current
      router.increment_order!
    end

    def path(*args)
      return @path if args.empty?
      params = args[0]
      params.delete(:captures)
      matcher.expand(params) if matcher.mustermann?
    end

    def params(pattern, parameters = {})
      match_data = match(pattern)
      return { :captures => match_data.captures } if match_data.names.empty?
      params = matcher.handler.params(pattern, :captures => match_data) || {}
      symbolize(params).merge(parameters){|key, old, new| old || new }
    end

    def symbolize(parameters)
      parameters.inject({}){|result, (key, val)| result[key.to_sym] = val; result }
    end

    private :symbolize
  end
end
