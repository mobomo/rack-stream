module Rack
  class Stream
    module Handlers
      # This handler uses delegates WebSocket requests to faye-websocket
      class WebSocket < AbstractHandler
        def self.accepts?(app)
          ::Faye::WebSocket.websocket?(app.env)
        end

        def close
          @body.callback {
            @ws.close(@app.status)
          }
        end

        def open
          @ws = ::Faye::WebSocket.new(@app.env)
          @ws.onopen = lambda do |event|
            @body.each {|c| @ws.send(c)}
          end
        end
      end
    end
  end
end