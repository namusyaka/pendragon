require 'howl-router/router'

module Howl

  # Allow the verbs of these.
  HTTP_VERBS = [:get, :post, :delete, :put, :head]

  class << self
    # A new instance of Howl::Router
    # @see Howl::Router#initialize
    def new(&block)
      Router.new(&block)
    end
  
    # Yields Howl configuration block
    # @example
    #   Howl.configure do |config|
    #     config.enable_compiler = true
    #   end
    # @see Howl::Configuration
    def configure(&block)
      block.call(configuration) if block_given?
      configuration
    end
  
    # Returns Howl configuration
    def configuration
      @configuration ||= Configuration.new
    end

    # Resets Howl configuration
    def reset_configuration!
      @configuration = nil
    end
  end
end
