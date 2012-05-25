begin
  require 'faye'
rescue LoadError
  $stderr.puts "Faye is required, make sure you add it to your project"
end

module Rack
  class Stream
    module Handlers
      # Handler for [Faye](http://faye.jcoglan.com/). This handler
      # assumes that you have subscribed the the stream you're interested
      # in ahead of time, and will start streaming to the channel
      # specified by the request header X-FAYE-STREAM. You may also
      # optionally specify a request header X-FAYE-CLOSE to be notified
      # when the connection is closed. Otherwise, the close channel name
      # is the same as X-FAYE-STREAM with '/close' appended to it.
      #
      # ## Example
      # ```ruby
      # require 'faye'
      # require 'rack/stream/handlers/faye'
      #
      # # subscribe to channel before we start streaming
      # client = Faye::Client.new('http://localhost:9292/faye')
      # subscription = client.subscribe('/stream') do |message|
      #   # do stuff with streamed message
      # end
      #
      # # get notification of when stream is done
      # client.subscribe('/stream/close') do |message|
      #   subscription.cancel  # cancel subscription after stream is closed
      # end
      #
      # use Rack::Stream
      # ```
      #
      # ```sh
      # # closes immediately, name stream channel with X-FAYE-STREAM header
      # curl -H"X-FAYE-STREAM: /stream" -i -N http://localhost:9292/
      # ```
      class Faye < AbstractHandler
        TERM ||= '_FAYE_CHANNEL_CLOSE_'.freeze

        def self.accepts?(app)
          app.env['HTTP_X_FAYE_STREAM']
        end

        def initialize(app)
          super

          # channels
          client.subscribe '/rack/stream/faye/open' do |channel|

          end
        end

        # If multiple requests come in for the same stream_channel,
        # only one should publish chunks.
        #
        # what if the auth is different though?
        #
        # current_user.messages.added do |message|
        #   chunk message  # this is unique to request and should not be broadcast to everyone
        # end
        # def chunk(*chunks)
        #   super(*chunks) unless streaming?
        # end


        # could require that all X-FAYE-STREAM be generated uuid
        # X-RACK-STREAM: faye
        # js: get '/messages', x-rack-stream: faye
        # rb:   return faye stream_channel
        # js: faye.subscribe stream_channel
        #
        # very wasteful: every faye channel only serves 1 client :(
        # "correct" way is to support multiple protocols. pubsub is not a
        # protocol, so we're shoehorning it in.
        #
        # potentially support pub/sub in rack-stream:
        #
        # chunk message, :channel => '/rooms/5'
        # chunk message, :channel => '/global'
        #
        # ... 1 request to many responses. broadcast capability
        # ... not all handlers can support it
        # ... maybe it's ok b/c it'll be an optimization?
        # if #chunk supports options, then app #run_callbacks needs
        # to be rewritten
        def chunk(*args)
          options = args.pop if args.last.is_a? Hash
          channel = options[:channel] || stream_channel
          args.each do |a|
            client.publish channel, a
          end
        end

        def open
          @body.each do |c|
            # TODO: this can't be in open
            # publishes out to ALL clients
            # each time you open a connection, a client subscribes
            client.publish(stream_channel, c)
          end

          # closes thin connection, potentially give a json response body
          # for metadata, or additional headers
          @app.env['async.callback'].call [@app.status, @app.headers, []]
        end

        def close
          @body.callback {
            # TODO: this also broadcasts, bad.
            client.publish close_channel, TERM
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

        def streaming?

        end
      end
    end
  end
end
