require 'howl-router/router'

module Howl
  ##
  # Allow the verbs of these.
  HTTP_VERBS = [:get, :post, :delete, :put, :head]

  ##
  # A new instance of Howl::Router
  # @see Howl::Router#initialize
  def self.new(&block)
    Router.new(&block)
  end
end
