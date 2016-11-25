module Pendragon
  # A module for unifying magic numbers
  # @!visibility private
  module Constants
    module Http
      GET     = 'GET'.freeze
      POST    = 'POST'.freeze
      PUT     = 'PUT'.freeze
      DELETE  = 'DELETE'.freeze
      HEAD    = 'HEAD'.freeze
      OPTIONS = 'OPTIONS'.freeze

      NOT_FOUND             = 404.freeze
      METHOD_NOT_ALLOWED    = 405.freeze
      INTERNAL_SERVER_ERROR = 500.freeze
    end

    module Header
      CASCADE = 'X-Cascade'.freeze
    end

    module Env
      PATH_INFO      = 'PATH_INFO'.freeze
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze
    end
  end
end
