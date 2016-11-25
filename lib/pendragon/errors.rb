require 'rack/utils'

module Pendragon
  # Module for creating any error classes.
  module Errors
    # Class for handling HTTP error.
    class Base < StandardError
      attr_accessor :status, :headers, :message

      # Creates a new error class.
      #
      # @example
      #   require 'pendragon/errors'
      #
      #   BadRequest = Pendragon::Errors::Base.create(status: 400)
      #
      # @option [Integer] status
      # @option [Hash{String => String}] headers
      # @option [String] message
      # @return [Class]
      def self.create(**options, &block)
        Class.new(self) do
          options.each { |k, v| define_singleton_method(k) { v } }
          class_eval(&block) if block_given?
        end
      end

      # Returns default message.
      #
      # @see [Rack::Utils::HTTP_STATUS_CODES]
      # @return [String] default message for current status.
      def self.default_message
        @default_message ||= Rack::Utils::HTTP_STATUS_CODES.fetch(status, 'server error').downcase
      end

      # Returns default headers.
      #
      # @return [Hash{String => String}] HTTP headers
      def self.default_headers
        @default_headers ||= { 'Content-Type' => 'text/plain' }
      end

      # Constructs an instance of Errors::Base
      #
      # @option [Hash{String => String}] headers
      # @option [Integer] status
      # @option [String] message
      # @options payload
      # @return [Pendragon::Errors::Base]
      def initialize(headers: {}, status: self.class.status, message: self.class.default_message, **payload)
        self.headers = self.class.default_headers.merge(headers)
        self.status, self.message = status, message
        parse_payload(**payload) if payload.kind_of?(Hash) && respond_to?(:parse_payload)
        super(message)
      end

      # Converts self into response conformed Rack style.
      #
      # @return [Array<Integer, Hash{String => String}, #each>] response
      def to_response
        [status, headers, [message]]
      end
    end

    NotFound         = Base.create(status: 404)
    MethodNotAllowed = Base.create(status: 405) do
      define_method(:parse_payload) do |allows: [], **payload|
        self.headers['Allows'] = allows.join(?,) unless allows.empty?
      end
    end
  end
end
