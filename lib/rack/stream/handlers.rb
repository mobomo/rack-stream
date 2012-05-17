module Rack
  class Stream
    # A Handler is responsible for opening and closing connections
    # to stream content.
    module Handlers
      # @private
      # TODO: allow registration of custom protocols
      def find(app)
        if Faye::WebSocket.websocket?(app.env)
          WebSocket.new(app)
        elsif Faye::EventSource.eventsource?(app.env)
          EventSource.new(app)
        else
          Http.new(app)
        end
      end
      module_function :find

      # All handlers should inherit from `AbstractHandler`
      class AbstractHandler

        # @param app [Rack::Stream::App] reference to current request
        def initialize(app)
          @app  = app
          @body = DeferrableBody.new
        end

        # Enqueue content to be streamed at a later time.
        #
        # Optionally override this method if you need to control
        # the content at a protocol level.
        def chunk(*chunks)
          @body.chunk(*chunks)
        end

        # @private
        def open!
          open
        end

        # Implement `#open` to initiate a connection
        def open
          raise NotImplementedError
        end

        # @private
        def close!(flush = true)
          close
          @body.close!(flush)
        end

        # Implement `#close` for cleanup
        # `#close` is called before the DeferrableBody is succeeded.
        def close
          raise NotImplementedError
        end
      end

      # This Handler works under EventMachine aware Rack servers like Thin
      # and Rainbows! It does chunked transfer encoding.
      class Http < AbstractHandler
        TERM = "\r\n".freeze
        TAIL = "0#{TERM}#{TERM}".freeze

        def chunk(*chunks)
          super(*chunks.map {|c| encode_chunk(c)})
        end

        def open
          @app.headers['Transfer-Encoding'] = 'chunked'
          @app.headers.delete('Content-Length')
          @app.env['async.callback'].call [@app.status, @app.headers, @body]
        end

        def close
          @body.chunk(TAIL)  # tail is special and already encoded
        end

        private

        def encode_chunk(c)
          return nil if c.nil?

          size = Rack::Utils.bytesize(c)  # Rack::File?
          return nil if size == 0
          c.dup.force_encoding(Encoding::BINARY) if c.respond_to?(:force_encoding)
          [size.to_s(16), TERM, c, TERM].join
        end
      end

      # This handler uses delegates WebSocket requests to faye-websocket
      class WebSocket < AbstractHandler
        def close
          @body.callback {
            @ws.close(@app.status)
          }
        end

        def open
          @ws = Faye::WebSocket.new(@app.env)
          @ws.onopen = lambda do |event|
            @body.each {|c| @ws.send(c)}
          end
        end
      end

      # This handler uses delegates EventSource requests to faye-websocket
      class EventSource < AbstractHandler
        # TODO: browser initiates connection again, isn't closed
        def close
          @body.callback {
            @es.close
          }
        end

        def open
          @es = Faye::EventSource.new(@app.env)
          @es.onopen = lambda do |event|
            @body.each {|c| @es.send(c)}
          end
        end
      end
    end
  end
end