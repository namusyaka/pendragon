require 'pendragon/padrino/router'
require 'pendragon/padrino/route'
require 'pendragon/padrino/ext/instance_methods'
require 'pendragon/padrino/ext/class_methods'

module Pendragon
  module Padrino
    class << self
      def registered(app)
        app.extend(ClassMethods)
        app.send(:include, InstanceMethods)
      end
    end
  end
end
