require 'benchmark'
require 'pendragon'
require 'rack'

routers = %i[liner realism radix].map do |type|
  Pendragon[type].new do
    1000.times { |n| get "/#{n}", to: ->(env) { [200, {}, [n.to_s]] } }
    namespace :foo do
      get '/:user_id' do
        [200, {}, ['yahoo']]
      end
    end
  end
end

env = Rack::MockRequest.env_for("/999")

routers.each do |router|
  p "router_class: #{router.class}"
  p router.call(env)
end

Benchmark.bm do |x|
  routers.each do |router|
    x.report do
      10000.times do |n|
        router.call(env)
      end
    end
  end
end
