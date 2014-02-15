module Pendragon
  class Configuration

    # Enables to compile the routes
    # Improve the performance by using this option,
    # but some features will not work correctly.
    # @see Pendragon::Router#compile
    attr_accessor :enable_compiler

    # Constructs an instance of Pendragon::Configuration
    def initialize
      @enable_compiler = false
    end

    # Returns an instance variable
    def [](variable_name)
      instance_variable_get("@#{variable_name}")
    end

    # Returns a boolean of @enable_compiler
    def enable_compiler?
      !!@enable_compiler
    end
  end
end
