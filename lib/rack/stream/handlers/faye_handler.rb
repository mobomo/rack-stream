begin
  require 'faye'
rescue LoadError
  $stderr.puts "Faye is required, make sure you add it to your project"
end

module Rack
  class Stream
    module Handlers
      # Handler for [Faye](http://faye.jcoglan.com/)
      #
      # @example
      # require 'rack/stream/handlers/faye'
      # client = Faye::Client.new('http://localhost:9292/faye')
      # subscription = client.subscribe('/stream') do |message|
      #   # subscribe to stream before opening connection
      # end
      #
      # client.subscribe('/stream/close') do |message|
      #   subscription.cancel  # cancel subscription after stream is closed
      # end
      #
      # use Rack::Stream
      #
      # curl -H"X-FAYE-STREAM: /stream" -i -N http://localhost:9292/
      # 200 closes immediately, assumes you subscribed to /stream before hand
      class FayeHandler < AbstractHandler
        def self.accepts?(app)
          app.env['HTTP_X_FAYE_STREAM']
        end

        def open
          @body.each do |c|
            client.publish(stream_channel, c)
          end

          # closes thin connection, potentially give a json response body
          # for metadata, or additional headers
          @app.env['async.callback'].call [@app.status, @app.headers, []]
        end

        def close
          @body.callback {
            client.publish close_channel, '_FAYE_CHANNEL_CLOSE_'
          }
        end

        protected

        def client
          @app.env['faye.client']
        end

        def stream_channel
          @app.env['HTTP_X_FAYE_STREAM']
        end

        def close_channel
          @app.env['HTTP_X_FAYE_CLOSE'] || "#{stream_channel}/close"
        end
      end
    end
  end
end