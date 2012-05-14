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
        chunk "Chunky\n"
        count += 1
      end
    end
  end
  [200, {}, []]
}
