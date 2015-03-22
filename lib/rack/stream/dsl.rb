require 'forwardable'

module Rack
  class Stream
    # DSL to access Rack::Stream::App methods.
    #
    # ## Example
    # ```ruby
    # # config.ru
    # class App
    #   include Rack::Stream::DSL
    #
    #   # declare your rack endpoint with a block
    #   stream do
    #     # all `Rack::Stream::App` methods, and `env` are available to you
    #     chunk "Hello"
    #     before_close { chunk "Bye" }
    #
    #     # return a rack response
    #     [200, {'Content-Type' => 'text/plain'}, []]
    #   end
    # end
    #
    # run App.new
    # ```
    #
    # ## Rack Frameworks
    #
    # If you mix this module into a class that already responds to `#call`,
    # then you need to make `env` available so that methods can be delegated to
    # `env['rack.stream']`. There is no need to declare a `stream` block in this case.
    #
    # For example, Sinatra makes `env` available to its endpoints:
    #
    # ```ruby
    # class App < Sinatra::Base
    #   include Rack::Stream::DSL
    #
    #   get '/' do
    #     chunk "Hello"  # no need to declare stream block b/c `env` is available
    #   end
    # end
    # ```
    module DSL
      def self.included(base)
        base.extend ClassMethods
        base.extend Forwardable

        base.class_eval do
          unless base.respond_to? :call
            include InstanceMethods
            attr_reader :env
          end

          def_delegators :"env['rack.stream']", :after_open, :before_chunk, :chunk, :after_chunk, :before_close, :close, :after_close, :stream_transport, :after_connection_error
        end
      end

      module InstanceMethods
        # Rack #call method is defined on the instance.
        #
        # @raise StreamBlockNotDefined if `.stream` isn't called before
        #   the first request.
        def call(env)
          @env = env
          unless self.class._rack_stream_proc
            raise StreamBlockNotDefined.new
          end
          instance_eval &self.class._rack_stream_proc
        end
      end

      module ClassMethods
        # @private
        attr_reader :_rack_stream_proc

        # Declare your rack endpoint with `&blk`
        def stream(&blk)
          @_rack_stream_proc = blk
        end
      end

      class StreamBlockNotDefined < StandardError
        def initialize(message = nil)
          super("no stream block declared")
        end
      end
    end
  end
end
