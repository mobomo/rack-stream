module Rack
  class Stream
    # From [thin_async](https://github.com/macournoyer/thin_async)
    class DeferrableBody
      include EM::Deferrable

      # @param chunks - object that responds to each. holds initial chunks of content
      def initialize(chunks = [])
        @queue = []
        chunks.each {|c| chunk(c)}
      end

      # Enqueue a chunk of content to be flushed to stream at a later time
      def chunk(*chunks)
        @queue += chunks
        schedule_dequeue
      end

      # When rack attempts to iterate over `body`, save the block,
      # and execute at a later time when `@queue` has elements
      def each(&blk)
        @body_callback = blk
        schedule_dequeue
      end

      def empty?
        @queue.empty?
      end

      def close!(flush = true)
        EM.next_tick {
          if !flush || empty?
            succeed
          else
            schedule_dequeue
            close!(flush)
          end
        }
      end

      private

      def schedule_dequeue
        return unless @body_callback
        EM.next_tick do
          next unless c = @queue.shift
          @body_callback.call(c)
          schedule_dequeue unless empty?
        end
      end
    end
  end
end
