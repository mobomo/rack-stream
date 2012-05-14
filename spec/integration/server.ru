require 'rack/stream'

use Rack::Stream

run lambda {|env|
  env['rack.stream'].instance_eval do
    after_open do
      chunk "Chunky", "Monkey"
      EM.next_tick do
        chunk "Brownie", "Batter"
        close
      end
    end

    before_chunk do |chunks|
      chunks.map(&:upcase)
    end

    after_chunk do
      # TODO: how to test this
    end

    before_close do
      chunk "closing"
    end

    after_close do
      # TODO: how to test this in integration?
    end
  end
  [200, {'Content-Type' => 'text/plain'}, ['Hello', ' ', 'World']]
}