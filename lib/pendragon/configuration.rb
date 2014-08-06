module Pendragon
  # A class for configuration of Pendragon
  # @!visibility private
  class Configuration
    # Defines an accessor as boolean method
    # @example
    #   attr_boolean_accessor :accessor_name
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

    # Automatically converts response into Rack format.
    # Default value is `true`.
    # @see Pendragon::Router#invoke
    attr_boolean_accessor :auto_rack_format

    # Enables to lock for threaded environment.
    # If you enable this option, all requests to synchronize on a mutex lock
    attr_boolean_accessor :lock

    # Constructs an instance of Pendragon::Configuration
    def initialize
      @enable_compiler  = false
      @auto_rack_format = true
      @lock             = false
    end

    # Returns an instance variable
    def [](variable_name)
      instance_variable_get("@#{variable_name}")
    end
  end
end
