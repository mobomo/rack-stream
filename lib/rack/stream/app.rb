module Rack
  class Stream
    class App
      class UnsupportedServerError < StandardError; end
      class StateConstraintError < StandardError; end

      # The state of the connection
      #   :new
      #   :open
      #   :closed
      attr_reader :state

      # @private
      attr_reader :env

      attr_reader :status, :headers

      def initialize(app, options={})
        @app       = app
        @state     = :new
        @callbacks = Hash.new {|h,k| h[k] = []}
      end

      def call(env)
        EM.next_tick {open!(env)}
        ASYNC_RESPONSE
      end

      def status=(code)
        require_state :new
        @status = code
      end

      def headers=(hash)
        require_state :new
        @headers = hash
      end

      def chunk(*chunks)
        require_state :new, :open
        run_callbacks(:chunk, chunks) {|mutated_chunks|
          @handler.chunk(*mutated_chunks)
        }
      end
      alias :<< :chunk

      def close(flush = true)
        require_state :open

        # run in the next tick since it's more natural to call #chunk right
        # before #close
        EM.next_tick {
          run_callbacks(:close) {
            @state = :closed
            @handler.close!(flush)
          }
        }
      end

      # @return [String] name of the handler for this request
      def stream_transport
        @handler and @handler.class.name.split('::').last
      end

      def new?;     @state == :new     end
      def open?;    @state == :open    end
      def closed?;  @state == :closed  end
      def errored?; @state == :errored end

      def report_connection_error
        # notify callbacks about the connection error
        run_callbacks(:connection_error)
      end

      private
      ASYNC_RESPONSE = [-1, {}, []].freeze

      def require_state(*allowed_states)
        unless allowed_states.include?(@state)
          action = caller[0]
          raise StateConstraintError.new("\nCalled\n  '#{caller[0]}'\n  Allowed :#{allowed_states * ','}\n  Current :#{@state}")
        end
      end

      # Transition state from :new to :open
      #
      # Freezes headers to prevent further modification
      def open!(env)
        @env = env
        @env['rack.stream'] = self
        raise UnsupportedServerError.new "missing async.callback. run within thin or rainbows" unless @env['async.callback']

        run_callbacks(:open) {
          @handler = Handlers.find(self)
          @status, @headers, app_body = @app.call(@env)

          # chunk any downstream response bodies
          app_body.each {|body| chunk(body)}
          after_open {close} if @callbacks[:after_open].empty?

          @handler.open!
          @state = :open
          @headers.freeze
        }
      end

      # Skips any remaining chunks, and immediately closes the connection
      def error!(e)
        @env['rack.errors'].puts(e.message)
        @status = 500 if new?
        @state  = :errored
        @handler.close!(false)
      end

      def self.define_callbacks(name, *types)
        types.each do |type|
          callback_name = "#{type}_#{name.to_s}"
          define_method callback_name do |&blk|
            @callbacks[callback_name.to_sym] << blk
            self
          end
        end
      end
      define_callbacks :open,  :after
      define_callbacks :chunk, :before, :after
      define_callbacks :close, :before, :after
      define_callbacks :connection_error, :after

      def run_callbacks(name, *args)
        EM.synchrony do
          modified = @callbacks["before_#{name}".to_sym].inject(args) do |memo, cb|
            [cb.call(*memo)]
          end
          yield(*modified) if block_given?
          @callbacks["after_#{name}".to_sym].each {|cb| cb.call(*args)}
        end
      rescue StateConstraintError => e
        error!(e)
      end
    end
  end
end
