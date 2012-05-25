module Rack
  class Stream
    module Handlers
      # Handler to stream to EventSource
      class EventSource < AbstractHandler
        def self.accepts?(app)
          Faye::EventSource.eventsource?(app.env)
        end

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

