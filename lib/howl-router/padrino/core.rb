require 'howl-router' unless defined?(Howl)

class Howl
  module Padrino
    class Core < ::Howl
      def add(verb, path, options = {}, &block)
        route = Route.new(path, &block)
        route.path_for_generation = options[:path_for_generation] if options[:path_for_generation]
        route.verb = verb.downcase.to_sym
        route.router = router
        router.routes << route
        route
      end

      def call(env)
        request  = Request.new(env)
        return bad_request unless HTTP_VERBS.include?(request.request_method.downcase.to_sym)
        compile unless compiled?
        begin
          matched_routes = recognize(request)
          [200, {}, matched_routes]
        rescue NotFound, MethodNotAllowed
          $!.call
        end
      end

      def path(name, *args)
        params = args.delete_at(args.last.is_a?(Hash) ? -1 : 0) || {}
        saved_args = args.dup
        router.routes.each do |route|
          next unless route.name == name
          matcher = route.matcher
          if !args.empty? and matcher.mustermann?
            matcher_names = matcher.names
            params_for_expand = Hash[matcher_names.map{|matcher_name|
              [matcher_name.to_sym, (params[matcher_name.to_sym] || args.shift)]
            }]
            params_for_expand.merge!(Hash[params.select{|k, v| !matcher_names.include?(name.to_sym) }])
            args = saved_args.dup
          else
            params_for_expand = params.dup
          end
          return matcher.mustermann? ? matcher.expand(params_for_expand) : route.path_for_generation
        end
        raise InvalidRouteException
      end
    end
  end
end
