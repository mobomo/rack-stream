# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

require ::File.expand_path '../../grape/api', __FILE__

map '/' do
  run Chat::Application
end

map '/messages' do
  use Rack::Stream
  run API
end
