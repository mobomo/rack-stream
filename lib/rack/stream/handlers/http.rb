module Rack
  class Stream
    module Handlers
      # This Handler works under EventMachine aware Rack servers like Thin
      # and Rainbows! It does chunked transfer encoding.
      class Http < AbstractHandler
        TERM = "\r\n".freeze
        TAIL = "0#{TERM}#{TERM}".freeze

        def self.accepts?(app)
          true
        end

        def chunk(*chunks)
          super(*chunks.map {|c| encode_chunk(c)})
        end

        def open
          @app.headers['Transfer-Encoding'] = 'chunked'
          @app.env['async.callback'].call [@app.status, @app.headers, @body]
        end

        def close
          @body.chunk(TAIL)  # tail is special and already encoded
        end

        private

        def encode_chunk(c)
          return nil if c.nil?
          # hack to work with Rack::File for now, should not TE chunked
          # things that aren't strings or respond to bytesize
          c = ::File.read(c.path) if c.kind_of?(Rack::File)
          size = c.bytesize
          return nil if size == 0
          c.dup.force_encoding(Encoding::BINARY) if c.respond_to?(:force_encoding)
          [size.to_s(16), TERM, c, TERM].join
        end
      end
    end
  end
end