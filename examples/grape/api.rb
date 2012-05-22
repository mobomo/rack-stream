require 'grape'
require 'rack/stream'
require 'redis'
require 'redis/connection/synchrony'

class API < Grape::API
  default_format :json

  helpers do
    include Rack::Stream::DSL

    def redis
      @redis ||= Redis.new
    end

    def build_message(text)
      m = {:text => text, :stream_transport => stream_transport}.to_json
      redis.rpush 'messages', m
      redis.ltrim 'messages', 0, 50
      redis.publish 'messages', m
      m
    end
  end

  resources :messages do
    get do
      after_open do
        # subscribe after_open b/c this runs until the connection is closed
        redis.subscribe 'messages' do |on|
          on.message do |channel, msg|
            chunk msg
          end
        end
      end

      status 200
      header 'Content-Type', 'application/json'
      redis.lrange 'messages', 0, 50
    end

    post do
      status 201
      build_message(params[:text])
    end
  end
end