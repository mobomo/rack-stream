require 'eventmachine'
require 'em-synchrony'
require 'faye/websocket'

# By default, handle these protocols, there are additional
# handlers available in rack/stream/handlers
require 'rack/stream/handlers'
require 'rack/stream/handlers/web_socket'
require 'rack/stream/handlers/event_source'
require 'rack/stream/handlers/http'

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