module Pendragon
  class ErrorHandler < StandardError
    def call
      response = []
      response << (settings[:status] || default_response[0])
      response << (settings[:headers] || default_response[1])
      response << Array(settings[:body] || default_response[2])
    end

    def settings
      self.class.settings
    end

    class << self
      def set(key, value)
        settings[key] = value
      end

      def settings
        @settings ||= {}
      end
    end

    private

    def default_response
      @default_response ||= [404, {'Content-Type' => 'text/html'}, ["Not Found"]]
    end
  end

  NotFound = Class.new(ErrorHandler)
  InvalidRouteException = Class.new(ArgumentError)

  class MethodNotAllowed < ErrorHandler
    ALLOW   = "Allow".freeze
    COMMA   = ", ".freeze

    set :status, 405
    set :body,   "Method Not Allowed"

    def initialize(verbs)
      default_response[1].merge!(ALLOW => verbs.map{|verb| verb.upcase } * COMMA)
    end
  end

  class BadRequest < ErrorHandler
    set :status, 400
    set :body,   "Bad Request"
  end
end
