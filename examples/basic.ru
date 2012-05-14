require 'rack/stream'

use Rack::Stream

run lambda {|env|
  [200, {'Content-Type' => 'text/plain'}, ['hello', ' ', 'world']]
}
