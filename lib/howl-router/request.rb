require 'rack'

class Howl
  class Request < Rack::Request
    attr_accessor :acceptable_methods
  end
end
