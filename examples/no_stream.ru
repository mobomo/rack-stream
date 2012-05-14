use Rack::Chunked
run lambda {|env|
  [200, {'Content-Type' => 'text/plain'}, ['hello', 'world']]
}
