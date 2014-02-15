require 'pendragon/router'

module Pendragon

  # Allow the verbs of these.
  HTTP_VERBS = [:get, :post, :delete, :put, :head]

  class << self
    # A new instance of Pendragon::Router
    # @see Pendragon::Router#initialize
    def new(&block)
      Router.new(&block)
    end
  
    # Yields Pendragon configuration block
    # @example
    #   Pendragon.configure do |config|
    #     config.enable_compiler = true
    #   end
    # @see Pendragon::Configuration
    def configure(&block)
      block.call(configuration) if block_given?
      configuration
    end
  
    # Returns Pendragon configuration
    def configuration
      @configuration ||= Configuration.new
    end

    # Resets Pendragon configuration
    def reset_configuration!
      @configuration = nil
    end
  end
end
