module Pendragon
  module Padrino
    module InstanceMethods
      private

      def invoke_route(route, params, options = {})
        original_params, parent_layout, successful = @params.dup, @layout, false
        captured_params = params[:captures].is_a?(Array) ? params.delete(:captures) :
                                                           params.values_at(*route.matcher.names.dup)

        @_response_buffer = nil
        @route = request.route_obj = route
        @params.merge!(params) if params.is_a?(Hash)
        @params.merge!(:captures => captured_params) if !captured_params.empty? && route.path.is_a?(Regexp)
        @block_params = params

        filter! :before if options[:first]

        catch(:pass) do
          begin
            (route.before_filters - settings.filters[:before]).each{|block| instance_eval(&block) }
            @layout = route.use_layout if route.use_layout
            route.custom_conditions.each {|block| pass if block.bind(self).call == false }
            halt_response     = catch(:halt){ route_eval{ route.block[self, captured_params] }}
            @_response_buffer = halt_response.is_a?(Array) ? halt_response.last : halt_response
            successful        = true
            halt(halt_response)
          ensure
            (route.after_filters - settings.filters[:after]).each {|block| instance_eval(&block) } if successful
            @layout, @params = parent_layout, original_params
          end
        end
      end

      def route!(base = settings, pass_block = nil)
        Thread.current['padrino.instance'] = self
        code, headers, routes = base.compiled_router.call(@request.env)

        status(code)
        if code == 200
          routes.each_with_index do |(route, pendragon_params), index|
            next if route.user_agent && !(route.user_agent =~ @request.user_agent)
            invoke_route(route, pendragon_params, :first => index.zero?)
          end
        else
          route_eval do
            headers.each{|k, v| response[k] = v } unless headers.empty?
            route_missing if code == 404
            route_missing if allow = response['Allow'] and allow.include?(request.env['REQUEST_METHOD'])
          end
        end

        if base.superclass.respond_to?(:router)
          route!(base.superclass, pass_block)
          return
        end

        route_eval(&pass_block) if pass_block
        route_missing
      end
    end
  end
end
