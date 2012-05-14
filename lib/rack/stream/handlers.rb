module Rack
  class Stream
    module Handlers
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

      class AbstractHandler
        def initialize(app)
          @app = app
        end

        def chunk(*chunks)
          raise NotImplementedError
        end

        def open!
          raise NotImplementedError
        end

        def close!(flush = true)
          raise NotImplementedError
        end
      end

      class Http < AbstractHandler
        TERM = "\r\n".freeze
        TAIL = "0#{TERM}#{TERM}".freeze

        def initialize(app)
          super
          @app.headers['Transfer-Encoding'] = 'chunked'
          @app.headers.delete('Content-Length')
          @body = DeferrableBody.new  # swap this out for different body types
        end

        def chunk(*chunks)
          @body.chunk(*chunks.map {|c| encode_chunk(c)})
        end

        def open!
          @app.env['async.callback'].call [@app.status, @app.headers, @body]
        end

        def close!(flush = true)
          @body.chunk(TAIL)  # tail is special and already encoded
          @body.close!(flush)
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

      class WebSocket < AbstractHandler
        def chunk(*chunks)
          # this is not called until after #open!, so @ws is always defined
          chunks.each {|c| @ws.send(c)}
        end

        def close!(flush = true)
          @ws.close(@app.status)
        end

        def open!
          @ws = Faye::WebSocket.new(@app.env)
        end
      end

      class EventSource < WebSocket
        def chunk(*chunks)
          chunks.each {|c| @es.send(c)}
        end

        def close!(flush = true)
          @es.close
        end

        def open!
          @es = Faye::EventSource.new(@app.env)
        end
      end
    end
  end
end