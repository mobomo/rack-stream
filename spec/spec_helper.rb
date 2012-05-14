require 'bundler/setup'
require 'rack'
require 'rack/stream'
require 'rack/test'
require 'rspec'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each {|f| require f}

# Used by tests to untangle evented code, but not required for use w/ lib
require 'fiber'
require 'timeout'

# TODO: swap this with em-spec or something else
# Patch rspec to run examples in a reactor
# based on em-rspec, but with synchrony pattern and does not auto stop the reactor
RSpec::Core::Example.class_eval do
  alias ignorant_run run

  def run(example_group_instance, reporter)
    EM.run do
      Fiber.new do
        EM.add_timer(2) {
          raise Timeout::Error.new("aborting test due to timeout")
          EM.stop
        }
        @ignorant_success = ignorant_run example_group_instance, reporter
      end.resume
    end
    @ignorant_success
  end
end

RSpec.configure do |c|
  c.include Rack::Test::Methods
end