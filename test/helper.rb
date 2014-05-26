require 'bundler/setup'
ENV['PADRINO_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined?(PADRINO_ROOT)
require File.expand_path('../../lib/pendragon', __FILE__)

require 'minitest/autorun'
require 'minitest/spec'
require 'mocha/setup'
require 'padrino-core'
require 'rack'
require 'rack/test'

begin
  require 'ruby-debug'
rescue LoadError; end

class Sinatra::Base
  include MiniTest::Assertions
end

class MiniTest::Spec
  include Rack::Test::Methods

  def pendragon
    @app = Pendragon.new
  end

  def enable_compiler?
    Pendragon.configuration.enable_compiler?
  end

  def mock_app(base = nil, &block)
    @app = Sinatra.new(base || ::Padrino::Application, &block)
  end

  def app
    Rack::Lint.new(@app)
  end

  def method_missing(name, *args, &block)
    if response && response.respond_to?(name)
      response.send(name, *args, &block)
    else
      super(name, *args, &block)
    end
  rescue Rack::Test::Error # no response yet
    super(name, *args, &block)
  end
  alias response last_response

  class << self
    alias :setup :before unless defined?(Rails)
    alias :teardown :after unless defined?(Rails)
    alias :should :it
    alias :context :describe
    def should_eventually(desc)
      it("should eventually #{desc}") { skip("Should eventually #{desc}") }
    end
  end
  alias :assert_no_match :refute_match
  alias :assert_not_nil :refute_nil
  alias :assert_not_equal :refute_equal
end


if defined?(MiniTest::Unit.output)
  class ColoredIO
    def initialize(io)
      @io = io
    end
  
    def print(o)
      case o
      when "." then @io.send(:print, o.colorize(:green))
      when "E" then @io.send(:print, o.colorize(:red))
      when "F" then @io.send(:print, o.colorize(:yellow))
      when "S" then @io.send(:print, o.colorize(:magenta))
      else @io.send(:print, o)
      end
    end
  
    def puts(*o)
      super
    end
  end
  MiniTest::Unit.output = ColoredIO.new($stdout)
else
  require 'minitest/pride'
end
