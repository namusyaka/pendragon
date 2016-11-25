require 'pendragon/router'
require 'thread'

module Pendragon
  # Type to use if no type is given.
  # @api private
  DEFAULT_TYPE = :realism

  # Creates a new router.
  # 
  # @example creating new routes.
  #   require 'pendragon'
  #
  #    Pendragon.new do
  #      get('/') { [200, {}, ['hello world']] }
  #      namespace :users do
  #        get('/',    to: ->(env) { [200, {}, ['User page index']] })
  #        get('/:id', to: UserApplication.new)
  #      end
  #    end
  #
  # @yield block for definig routes, it will be evaluated in instance context.
  # @yieldreturn [Pendragon::Router]
  def self.new(type: DEFAULT_TYPE, &block)
    type ||= DEFAULT_TYPE
    self[type].new(&block)
  end

  @mutex ||= Mutex.new
  @types ||= {}

  # Returns router by given name.
  #
  # @example
  #   Pendragon[:realism] #=> Pendragon::Realism
  #
  # @param [Symbol] name a router type identifier
  # @raise [ArgumentError] if the name is not supported
  # @return [Class, #new]
  def self.[](name)
    @types.fetch(normalized = normalize_type(name)) do
      @mutex.synchronize do
        error = try_require "pendragon/#{normalized}"
        @types.fetch(normalized) do
          fail ArgumentError,
            "unsupported type %p #{ " (#{error.message})" if error }" % name
        end
      end
    end
  end

  # @return [LoadError, nil]
  # @!visibility private
  def self.try_require(path)
    require(path)
    nil
  rescue LoadError => error
    raise(error) unless error.path == path
    error
  end

  # @!visibility private
  def self.register(name, type)
    @types[normalize_type(name)] = type
  end

  # @!visibility private
  def self.normalize_type(type)
    type.to_s.gsub('-', '_').downcase
  end
end
