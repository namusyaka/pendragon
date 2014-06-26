require 'pendragon/router'

module Pendragon

  # Allow the verbs of these.
  HTTP_VERBS = %w[GET POST PUT PATCH DELETE HEAD OPTIONS LINK UNLINK]

  class << self
    # A new instance of Pendragon::Router
    # @see Pendragon::Router#initialize
    def new(&block)
      Router.new(&block)
    end
  
    # @deprecated
    # Yields Pendragon configuration block
    # @example
    #   Pendragon.configure do |config|
    #     config.enable_compiler = true
    #   end
    # @see Pendragon::Configuration
    def configure(&block)
      configuration_warning(:configure)
      block.call(configuration) if block_given?
      configuration
    end
  
    # @deprecated
    # Returns Pendragon configuration
    def configuration
      configuration_warning(:configuration)
      @configuration ||= Configuration.new
    end

    # @deprecated
    # Resets Pendragon configuration
    def reset_configuration!
      @configuration = nil
    end

    private

    def configuration_warning(method)
      warn <<-WARN
Pendragon.#{method} is deprecated because it isn't thread-safe.
Please use new syntax.
Pendragon.new do |config|
  config.auto_rack_format = false
  config.enable_compiler  = true
end
      WARN
    end
  end
end
