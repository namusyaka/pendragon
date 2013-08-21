
class Howl
  module Padrino
    module InstanceMethods
      private
        def route!(base = settings, pass_block = nil)
          Thread.current['padrino.instance'] = self
          code, headers, routes = base.compiled_router.call(@request.env)

          status(code)
          if code == 200
            routes.each_with_index do |route_pair, index|
              route = route_pair[0]
              next if route.user_agent && !(route.user_agent =~ @request.user_agent)
              original_params, parent_layout, successful = @params.dup, @layout, false

              howl_params     = route_pair[1]
              param_names     = route.matcher.names.dup
              captured_params = howl_params[:captures].is_a?(Array) ? howl_params.delete(:captures) : howl_params.values_at(*param_names)

              @route = request.route_obj = route
              @params.merge!(howl_params) if howl_params.is_a?(Hash)
              @params.merge!(:captures => captured_params) unless captured_params.empty?
              @block_params = howl_params

              filter! :before if index == 0

              catch(:pass) do
                begin
                  (route.before_filters - settings.filters[:before]).each{|block| instance_eval(&block) }
                  @layout = route.use_layout if route.use_layout
                  route.custom_conditions.each {|block| pass if block.bind(self).call == false } unless route.custom_conditions.empty?
                  halt_response = catch(:halt){ route_eval{ route.block[self, captured_params] }}
                  successful    = true
                  halt(halt_response)
                ensure
                   (route.after_filters - settings.filters[:after]).each {|block| instance_eval(&block) } if successful
                   @layout, @params = parent_layout, original_params
                end
              end
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
