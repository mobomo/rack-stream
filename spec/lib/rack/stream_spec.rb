require 'spec_helper'

describe Rack::Stream do
  def app
    b = Rack::Builder.new
    b.use Support::MockServer
    b.use Rack::Stream
    b.run endpoint
    b
  end

  shared_examples_for 'invalid action' do
    it "should raise invalid state" do
      get '/'
      last_response.errors.should =~ /Invalid action/
      last_response.status.should == 500
    end
  end

  let(:endpoint) {
    lambda {|env| [201, {'Content-Type' => 'text/plain', 'Content-Length' => 11}, ["Hello world"]]}
  }

  before {get '/'}

  context "defaults" do
    it "should close connection with status" do
      last_response.status.should == 201
    end

    it "should set headers" do
      last_response.headers['Content-Type'].should == 'text/plain'
    end

    it "should not error" do
      last_response.errors.should == ""
    end

    it "should remove Content-Length header" do
      last_response.headers['Content-Length'].should be_nil
    end

    it "should use chunked transfer encoding" do
      last_response.headers['Transfer-Encoding'].should == 'chunked'
    end
  end

  context "queued content" do
    let(:endpoint) {
      lambda {|env|
        env['rack.stream'].instance_eval do
          chunk "Chunky"
        end
        [200, {}, ['']]
      }
    }

    it "should allow chunks to be queued outside of callbacks" do
      last_response.body.should == "6\r\nChunky\r\n0\r\n\r\n"
    end
  end

  context "basic streaming" do
    let(:endpoint) {
      lambda {|env|
        env['rack.stream'].instance_eval do
          after_open do
            chunk "Chunky "
            chunk "Monkey"
            close
          end
        end
        [200, {'Content-Length' => 0}, ['']]
      }
    }

    it "should stream and close" do
      last_response.status.should == 200
      # last_response.body.should == "Chunky Monkey"
      last_response.body.should == "7\r\nChunky \r\n6\r\nMonkey\r\n0\r\n\r\n"
    end
  end

  context "before chunk" do
    let(:endpoint) {
      lambda {|env|
        env['rack.stream'].instance_eval do
          after_open do
            chunk "Chunky", "Monkey"
            close
          end

          before_chunk {|chunks| chunks.map(&:upcase)}
          before_chunk {|chunks| chunks.reverse}
        end
        [200, {}, []]
      }
    }

    it 'should allow modification of queued chunks' do
      last_response.body.should == "6\r\nMONKEY\r\n6\r\nCHUNKY\r\n0\r\n\r\n"
    end
  end

  context "before close" do
    let(:endpoint) {
      lambda {|env|
        env['rack.stream'].instance_eval do
          before_close do
            chunk "Chunky "
            chunk "Monkey"
          end
        end
        [200, {}, []]
      }
    }

    it "should stream and close" do
      last_response.body.should == "7\r\nChunky \r\n6\r\nMonkey\r\n0\r\n\r\n"
    end
  end

  context "after close" do
    let(:endpoint) {
      lambda {|env|
        env['rack.stream'].instance_eval do
          after_close do
            $after_close_called = true
          end
        end
        [200, {}, []]
      }
    }

    it "should allow cleanup" do
      $after_close_called.should be_true
      $after_close_called = nil
    end
  end
end