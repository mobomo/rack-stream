require 'rack/stream'

use Rack::Stream

run lambda {|env|
  env["rack.stream"].instance_eval do
    count = 0
    after_open do
      timer = EM::PeriodicTimer.new(0.1) do
        if count > 10
          timer.cancel
          close
        end
        chunk "\nChunky"
        count += 1
      end
    end

    before_chunk do |chunks|
      chunks.map(&:upcase)
    end

    before_close do
      chunk "\nBye"
    end
  end
  [200, {}, ['Hello']]
}
