require File.expand_path('../helper', __dir__)

class TestRealism < Test::Unit::TestCase
  include Supports::SharedExamplesForRouting
  router_class Pendragon::Realism
end
