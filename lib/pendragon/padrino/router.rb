require 'pendragon' unless defined?(Pendragon::Router)

module Pendragon
  module Padrino
    class Router < Pendragon::Router
      def add(verb, path, options = {}, &block)
        route = Route.new(path, verb, options, &block)
        route.path_for_generation = options[:path_for_generation] if options[:path_for_generation]
        route.router = self
        routes << route
        route
      end

      def call(env)
        request = Rack::Request.new(env)
        [200, {}, recognize(request)]
      rescue BadRequest, NotFound, MethodNotAllowed
        $!.call
      end

      def path(name, *args)
        extract_with_name(name, *args) do |route, params, matcher|
          matcher.mustermann? ? matcher.expand(params) : route.path_for_generation
        end
      end

      def configuration
        @configuration ||= Pendragon::Configuration.new
      end
    end
  end
end
