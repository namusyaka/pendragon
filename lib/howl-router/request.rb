require 'rack'

class Howl
  class Request < Rack::Request
    attr_accessor :acceptable_methods

    def path_info
      Rack::Utils.unescape super
    end
  end
end
