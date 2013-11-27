class Howl
  class ErrorHandler < StandardError
    def call
      response = []
      response << (settings[:status]  || default_response[0])
      response << (settings[:headers] || default_response[1])
      response << (settings[:body]    || default_response[2])
    end

    def settings
      self.class.settings
    end

    class << self
      def set(key, value)
        settings[key] = value
      end

      def settings
        @settings ||= {}
      end
    end

    private

    def default_response
      @default_response ||= [404, {'Content-Type' => 'text/html'}, ["Not Found"]]
    end
  end
end
