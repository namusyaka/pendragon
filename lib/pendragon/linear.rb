require 'pendragon/router'

module Pendragon
  class Linear < Router
    register :linear

    on(:call) { |env| rotation(env) { |route| route.exec(env) } }
  end
end
