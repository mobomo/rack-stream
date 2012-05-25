# CI test. see .travis.yml for config variables
if ENV['SERVER']
  require 'bundler/setup'
  require 'rack'
  require 'rack/stream'
  require 'rspec'

  require 'capybara/rspec'
  require 'faraday'
  require 'em-eventsource'
  require 'capybara'
  require 'capybara-webkit'

  describe 'Integration', :integration => true, :type => :request, :driver => :webkit do
    EXPECTED = 'HELLO WORLDCHUNKYMONKEYBROWNIEBATTERCLOSING'.freeze
    let(:uri) {URI.parse(ENV['SERVER'])}

    before :all do
      Capybara.app_host   = uri.to_s
      Capybara.run_server = false
    end

    describe 'HTTP' do
      it 'should stream with chunked transfer encoding' do
        http = Faraday.new uri.to_s
        2.times.map do
          res = http.get '/'
          res.status.should == 200
          res.headers['content-type'].should == 'text/plain'
          res.headers['transfer-encoding'].should == 'chunked'
          res.body.should == EXPECTED
        end
      end
    end

    describe 'WebSocket' do
      it 'should stream with websockets' do
        uri.scheme = 'ws'
        EM.run {
          ws = Faye::WebSocket::Client.new(uri.to_s)
          # ws.onopen    = lambda {|e| puts 'opened'}
          $ws_chunks = []
          ws.onmessage = lambda {|e| $ws_chunks << e.data}
          ws.onclose = lambda do |e|
            EM.stop
            $ws_chunks.join('').should == EXPECTED
            $ws_chunks = nil
          end
        }
      end
    end

    describe 'EventSource' do
      # em-eventsource needs to send 'Accept' => 'text/event-stream'
      # not sure if the gem isn't working or if its rack-stream. a web integration spec would be nice
      # it 'should stream with eventsource' do
      #   @chunks = ""
      #   source = EventMachine::EventSource.new(uri.to_s)
      #   source.message do |message|
      #     puts message
      #     @chunks << message
      #     source.stop if @chunks == EXPECTED
      #   end
      #   source.start
      # end
    end

    describe 'Javascript', :type => :request, :driver => :webkit do
      it 'should work from a js client' do
        visit '/capybara'
        # capybara doesn't distinguish between " " and ""
        all('#ws li').map(&:text).should =~ ["socket opened", "HELLO", "", "WORLD", "CHUNKY", "MONKEY", "BROWNIE", "BATTER", "CLOSING", "socket closed"]

        all('#es li').map(&:text).should =~ ["HELLO", "", "WORLD", "CHUNKY", "MONKEY", "BROWNIE", "BATTER", "CLOSING"]
      end
    end
  end
end