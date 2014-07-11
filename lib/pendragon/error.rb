module Pendragon
  # Raises the exception if routes that matches the condition do not exist
  InvalidRouteException = Class.new(ArgumentError)

  # A base class for error responses
  # ResponseError#status and ResponseError#body must be implemented by subclass
  class ResponseError < StandardError
    def initialize(*args)
      @args = args
    end

    def call
      [status, headers, Array(body)]
    end

    def status
      raise NotImplementedError, "`status` must be implemented by subclass"
    end

    def body
      raise NotImplementedError, "`body` must be implemented by subclass"
    end

    def headers
      @headers ||= { "Content-Type" => "text/plain" }
    end
  end

  # A class for BadRequest response
  class BadRequest < ResponseError
    def status
      @status ||= 400
    end

    def body
      @body ||= "Bad Request"
    end
  end

  # A class for NotFound response
  class NotFound < ResponseError
    def status
      @status ||= 404
    end

    def body
      @body ||= "Not Found"
    end
  end

  # A class for MethodNotAllowed response
  class MethodNotAllowed < ResponseError
    ALLOW = "Allow".freeze
    COMMA = ", ".freeze

    def status
      @status ||= 405
    end

    def body
      @body ||= "Method Not Allowed"
    end

    def headers
      @headers ||= begin
        super_headers = super
        super_headers.merge!(ALLOW => @args.shift.map{|verb| verb.upcase } * COMMA)
      end
    end
  end
end
