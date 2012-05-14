require 'eventmachine'
require 'faye/websocket'

require 'rack/stream/handlers'
require 'rack/stream/deferrable_body'
require 'rack/stream/app'
require 'rack/stream/dsl'

module Rack
  # Middleware for building multi-protocol streaming rack endpoints.
  class Stream
    def initialize(app, options={})
      @app = app
    end

    def call(env)
      App.new(@app).call(env)
    end
  end
end