require File.expand_path('helper', __dir__)

class TestRouter < Test::Unit::TestCase
  attr_accessor :router

  setup { self.router = Pendragon::Router.new }

  sub_test_case '#call' do
    setup do
      @mock_request = Rack::MockRequest.env_for(?/)
      router.get(?/) { 'hello' }
    end

    test 'should recognize a route inside #with_block' do
      router.expects(:with_optimization)
      router.call(@mock_request)
    end

    test 'raises NotImplementedError' do
      assert_raise NotImplementedError do
        router.call(@mock_request)
      end
    end

    sub_test_case 'without matched route' do
    end
  end

  %w[get post put delete head options].each do |request_method|
    sub_test_case "##{request_method}" do
      setup { @expected_block = Proc.new {} }
      test "should append #{request_method} route correctly" do
        router.public_send(request_method, ?/, &@expected_block)
        actual = router.map[request_method.upcase].first
        assert { actual.request_method == request_method.upcase }
        assert { actual.path == ?/ }
      end
    end
  end
end
