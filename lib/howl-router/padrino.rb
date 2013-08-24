require File.expand_path("../../howl", __FILE__) unless defined?(Howl)

%w[
  core
  route
  router
  matcher
  ext/instance_methods
  ext/class_methods
].each{|name| require File.expand_path("../padrino/#{name}", __FILE__) }

class Howl
  module Padrino
    class << self
      def registered(app)
        app.extend(ClassMethods)
        app.send(:include, InstanceMethods)
      end
    end
  end
end
