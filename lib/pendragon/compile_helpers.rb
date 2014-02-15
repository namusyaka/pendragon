
module Howl
  module CompileHelpers
    def compile!
      @compiled_regexps = Howl::HTTP_VERBS.inject({}){|all, verb| all[verb] = []; all }
      @routes.each_with_index do |route, index|
        regexp = route.matcher.handler
        regexp = regexp.to_regexp if route.matcher.mustermann?
        @compiled_regexps[route.verb] << /(?<_#{index}>#{regexp})/
        route.index = "_#{index}"
      end
      @compiled_regexps.each_pair{|verb, regexps| @compiled_regexps[verb] = /\A#{Regexp.union(regexps)}\Z/ }
    end

    def compiled?
      !!@compiled_regexps
    end

    def recognize_by_compiling_regexp(request)
      path_info, verb, request_params = parse_request(request)

      unless @compiled_regexps[verb] === path_info
        old_path_info = path_info
        path_info = path_info[0..-2] if path_info != "/" and path_info[-1] == "/"
        raise NotFound if old_path_info == path_info || !(@compiled_regexps[verb] === path_info)
      end

      route = @routes.select{|route| route.verb == verb }.detect{|route| Regexp.last_match(route.index) }
      params, match_data = {}, route.match(path_info)
      if match_data.names.empty?
        params[:captures] = match_data.captures
      else
        params.merge!(match_data.names.inject({}){|result, name|
          result[name.to_sym] = match_data[name] ? Rack::Utils.unescape(match_data[name]) : nil
          result
        }).merge!(request_params){|key, self_val, new_val| self_val || new_val }
      end
      [[route, params]]
    end
  end
end
