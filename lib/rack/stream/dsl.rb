require 'forwardable'

module Rack
  class Stream
    module DSL
      def self.included(base)
        base.class_eval do
          extend Forwardable
          def_delegators :rack_stream, :after_open, :before_chunk, :chunk, :after_chunk, :before_close, :close, :after_close, :stream_transport

          def rack_stream
            env['rack.stream']
          end
        end
      end
    end
  end
end