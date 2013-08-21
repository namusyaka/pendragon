
class Howl
  module Padrino
    class Core < ::Howl
      def add(verb, path, options = {}, &block)
        verb = verb.downcase.to_sym
        (router.routes_with_verbs[verb] ||= []) << (route = Route.new(path, &block))
        route.path_for_generation = options[:path_for_generation] if options[:path_for_generation]
        route.verb = verb
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
        rescue => evar
          case evar
          when NotFound then not_found
          when MethodNotAllowed then method_not_allowed('Allow' => request.acceptable_methods.sort.join(", "))
          else server_error
          end
        end
      end

      private

      def generate_response(key, headers = {})
        [RESPONSE_HEADERS[key], headers, [key.to_s.split('_').map(&:capitalize) * " "]]
      end
    end
  end
end
