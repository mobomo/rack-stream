require 'spec_helper'

describe Rack::Stream::DSL do
  subject do
    Class.new {include Rack::Stream::DSL}.new
  end

  before do
    EM.stop  # TODO: would prefer to have only stream_spec require em
  end

  context 'raw rack' do
    context '#call' do
      it 'should declare #call' do
        subject.respond_to?(:call).should be_true
      end

      it 'should raise error if no run block is defined' do
        expect {
          subject.call(mock)
        }.to raise_error(Rack::Stream::DSL::StreamBlockNotDefined)
      end
    end

    context '.run' do
      subject do
        Class.new {
          include Rack::Stream::DSL

          attr_reader :run_called
          stream do
            @run_called = true
          end
        }.new
      end

      it 'should eval run block for new requests' do
        subject.call(mock)
        subject.run_called.should be_true
      end
    end
  end

  context 'rack framework' do
    subject do
      Class.new {
        # mock of a rack web framework that already knows call
        def call(env)
        end

        include Rack::Stream::DSL
      }.new
    end

    context '#call' do
      it 'should raise error if no run block is defined' do
        expect {
          subject.call(mock)
        }.to_not raise_error(Rack::Stream::DSL::StreamBlockNotDefined)
      end
    end
  end
end