module Rack
  class Stream
    # A Handler is responsible for opening and closing connections
    # to stream content.
    module Handlers
      # @private
      def find(app)
        klass = AbstractHandler.handlers.detect {|h| h.accepts?(app)}
        klass.new(app)
      end
      module_function :find

      # A handler instance is responsible for managing the opening, streaming,
      # and closing for a particular protocol.
      #
      # All handlers should inherit from `AbstractHandler`. Subclasses that
      # inherit later have higher precedence than later subclassed handlers.
      class AbstractHandler
        class << self
          attr_reader :handlers

          def inherited(handler_class)
            @handlers ||= []
            @handlers.unshift(handler_class)
          end

          # Whether this handler knows how to handle a given request
          # @param app [Rack::Stream::App]
          def accepts?(app)
            raise NotImplementedError
          end
        end

        # @param app [Rack::Stream::App] reference to current request
        def initialize(app)
          @app  = app
          @body = DeferrableBody.new
          @body.errback { @app.report_connection_error }
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
          @app.headers.delete('Content-Length')
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
          # do nothing
        end
      end
    end
  end
end
