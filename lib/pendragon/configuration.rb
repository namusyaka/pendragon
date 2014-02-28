module Pendragon
  class Configuration

    # Define the accessor as boolean method
    def self.attr_boolean_accessor(*keys)
      keys.each do |key|
        attr_accessor key
        define_method("#{key}?"){ !!__send__(key) }
      end
    end

    # Enables to compile the routes
    # Improve the performance by using this option,
    # but some features will not work correctly.
    # @see Pendragon::Router#compile
    attr_boolean_accessor :enable_compiler

    # Automatically convert response into Rack format.
    # Default value is `true`.
    attr_boolean_accessor :auto_rack_format

    # Constructs an instance of Pendragon::Configuration
    def initialize
      @enable_compiler  = false
      @auto_rack_format = true
    end

    # Returns an instance variable
    def [](variable_name)
      instance_variable_get("@#{variable_name}")
    end
  end
end
