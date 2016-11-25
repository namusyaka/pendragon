require 'json'

module Supports::SharedExamplesForRouting
  extend Modulla
  include Rack::Test::Methods

  module ClassMethods
    def router_class(klass)
      define_method(:router) { klass }
    end

    def disable(*features)
      features.each do |feature|
        define_method('%p disabled' % feature) {}
      end
    end
  end

  alias_method :response, :last_response

  def disabled?(feature)
    respond_to?('%p disabled' % feature)
  end

  def mock_env_for(path = ?/, **options)
    Rack::MockRequest.env_for(path, **options)
  end

  def mock_app(base = nil, &block)
    @app = router.new(&block)
  end

  def app
    Rack::Lint.new(@app)
  end

  def assert_response(status, body, headers = {})
    assert { last_response.status  == status }
    assert { last_response.body    == body }
    headers.each_pair do |key, val|
      assert { last_response.headers[key] == val }
    end
  end

  sub_test_case '#call' do
    test 'return response conformed rack format' do
      assert_nothing_raised do
        Rack::Lint.new(router.new).call(mock_env_for)
      end
    end
  end

  sub_test_case 'default response' do
    setup { mock_app { } }
    test 'return default response if given request does not match with any routes' do
      get ?/
      assert_response 404, 'not found', 'Content-Type' => 'text/plain'
    end
  end

  sub_test_case 'basic' do
    setup do
      mock_app do
        get(?/) { [200, {}, ['hello']] }
      end
    end
    test 'return response if given request matches with any routes' do
      get ?/
      assert_response 200, 'hello'
    end
  end

  sub_test_case 'duck typing' do
    setup do
      _lambda = -> { [200, {}, ['lambda']] }
      rack_app_class = Class.new {
        def call(env)
          [200, {}, ['rackapp']]
        end
      }
      mock_app do
        get '/lambda',   to: _lambda
        get '/rack_app', to: rack_app_class.new
      end
    end

    test 'duck typing for lambda' do
      get '/lambda'
      assert_response 200, 'lambda'
    end

    test 'duck typing for rack app' do
      get '/rack_app'
      assert_response 200, 'rackapp'
    end
  end

  sub_test_case 'namespacing' do
    setup do
      mock_app do
        namespace :foo do
          get('/123') { [200, {}, ['hey']] }
        end
      end
    end

    test 'append given namespace as a prefix' do
      get '/foo/123'
      assert_response 200, 'hey'
    end
  end

  sub_test_case 'nested namespacing' do
    setup do
      mock_app do
        namespace :foo do
          get('/') { [200, {}, ['foo']] }
          namespace :bar do
            get('/') { [200, {}, ['bar']] }
            namespace :baz do
              get('/') { [200, {}, ['baz']] }
            end
          end
        end
      end
    end

    test 'append given namespace as a prefix' do
      get '/foo/'
      assert_response 200, 'foo'
      get '/foo/bar/'
      assert_response 200, 'bar'
      get '/foo/bar/baz/'
      assert_response 200, 'baz'
    end
  end

  sub_test_case 'complex routing' do
    setup do
      mock_app do
        1000.times do |n|
          [:get, :post, :put, :delete, :options].each do |verb|
            public_send(verb, "/#{n}") { [200, {}, ["#{verb} #{n}"]] }
          end
        end
      end
    end

    test 'recognize a route correctly' do
      put '/376'
      assert_response 200, 'put 376'
    end

    test 'recognize a route correctly (part 2)' do
      delete '/999'
      assert_response 200, 'delete 999'
    end
  end

  sub_test_case 'method not allowed' do
    setup do
      mock_app do
        get '/testing' do
          [200, {}, ['hello testing']]
        end
      end
    end

    test 'returns 405 if given method is not allowed' do
      post '/testing'
      assert_response 405, 'method not allowed', { 'Allows' => 'GET' }
    end
  end

  sub_test_case 'block arguments' do
    setup do
      mock_app do
        get '/foo/:name/*/*' do |name, a, b|
          body = "#{name}, #{a}, #{b}"
          [200, {}, [body]]
        end
      end
    end

    test 'gets params as block parameters' do
      omit_if disabled?(:multiple_splats)
      get '/foo/yoman/1234/5678'
      assert_response 200, 'yoman, 1234, 5678'
    end
  end

  sub_test_case '#params' do
    setup do
      mock_app do
        get '/foo/:name/*/*' do
          body = params.to_json
          [200, {}, [body]]
        end
      end
    end

    test 'gets params correctly' do
      omit_if disabled?(:multiple_splats)
      get '/foo/heyman/1234/5678'
      assert_response 200, {name: 'heyman', splat: ['1234', '5678']}.to_json
    end
  end

  sub_test_case 'capturing' do
    setup do
      mock_app do
        get '/users/:name/articles/:article_id' do
          [200, {}, [captures.join(' ')]]
        end
      end
    end

    test 'gets captures correctly' do
      get '/users/namusyaka/articles/1234'
      assert_response 200, 'namusyaka 1234'
    end
  end

  sub_test_case 'splat' do
    sub_test_case 'multiple splats' do
      setup do
        mock_app do
          get '/splatting/*/*/*' do |a, b, c|
            [200, {}, ["captures: #{captures.join(' ')}, block: #{a} #{b} #{c}"]]
          end
        end
      end

      test 'gets multiple splats correctly' do
        omit_if disabled?(:multiple_splats)
        get '/splatting/1234/5678/90'
        assert_response 200, 'captures: 1234 5678 90, block: 1234 5678 90'
      end
    end
  end

  sub_test_case 'cascading' do
    setup do
      mock_app do
        get '/cascading' do
          [200, { 'X-Cascade' => 'pass' }, ['']]
        end

        get '/cascading' do
          [200, {}, ['yay']]
        end
      end
    end

    test 'succeeds to cascading' do
      omit_if disabled?(:cascading)
      get '/cascading'
      assert_response 200, 'yay'
    end
  end

  sub_test_case 'halting' do
    setup do
      mock_app do
        get ?/ do
          throw :halt, [404, {}, ['not found']]
          [200, {}, ['failed to halt']]
        end
      end
    end

    test 'succeeds to halting' do
      get ?/
      assert_response 404, 'not found'
    end
  end
end
