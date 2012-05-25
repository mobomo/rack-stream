require 'sinatra/base'
require 'rack/stream'
require 'faye'

use Faye::RackAdapter, :mount => '/faye', :timeout => 5
use Rack::Stream

class App < Sinatra::Base
  include Rack::Stream::DSL

  get '/capybara' do
    erb :index
  end

  get '/' do
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

    before_close do
      chunk "closing"
    end

    status 200
    headers 'Content-Type' => 'text/plain'
    ['Hello', ' ', 'World']
  end
end

run App