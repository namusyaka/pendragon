require File.expand_path('../helper', __dir__)

class TestLinear < Test::Unit::TestCase
  include Supports::SharedExamplesForRouting
  router_class Pendragon::Linear
end
