require 'bundler/setup'
require File.expand_path('../lib/pendragon', __dir__)
require File.expand_path('../lib/pendragon/realism', __dir__)
require File.expand_path('../lib/pendragon/linear', __dir__)

Bundler.require(:default)

require 'test/unit'
require 'mocha/setup'
require 'rack'
require 'rack/test'

module Supports
end

$:.unshift(File.expand_path('..', __dir__))
Dir.glob('test/supports/*.rb').each(&method(:require))
