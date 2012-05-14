module Support
  class MockServer
    class Callback
      attr_reader :status, :headers, :body

      def initialize(&blk)
        @succeed_callback = blk
      end

      def call(args)
        @status, @headers, deferred_body = args
        @body = []
        deferred_body.each do |s|
          @body << s
        end
        deferred_body.callback {@succeed_callback.call}
        deferred_body.callback {EM.stop}
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      f = Fiber.current
      callback = Callback.new do
        f.resume [callback.status, callback.headers, callback.body]
      end
      env['async.callback'] = callback
      @app.call(env)
      Fiber.yield  # wait until deferred body is succeeded
    end
  end
end