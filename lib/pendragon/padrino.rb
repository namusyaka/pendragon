require 'howl-router/padrino/router'
require 'howl-router/padrino/route'
require 'howl-router/padrino/ext/instance_methods'
require 'howl-router/padrino/ext/class_methods'

module Howl
  module Padrino
    class << self
      def registered(app)
        app.extend(ClassMethods)
        app.send(:include, InstanceMethods)
      end
    end
  end
end
