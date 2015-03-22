# rack-stream [![Build Status](https://secure.travis-ci.org/intridea/rack-stream.png)](http://travis-ci.org/jch/rack-stream)

## Overview

rack-stream is middleware for building multi-protocol streaming rack endpoints.

## Installation

```ruby
# Gemfile
gem 'rack-stream'
```

```sh
bundle
```

## Example

```ruby
# config.ru
require 'rack/stream'

class App
  include Rack::Stream::DSL

  stream do
    after_open do
      count = 0
      @timer = EM.add_periodic_timer(1) do
        if count != 3
          chunk "chunky #{count}\n"
          count += 1
        else
          # Connection isn't closed until #close is called.
          # Useful if you're building a firehose API
          close
        end
      end
    end

    after_connection_error do
      # connection has been lost / terminated by the client, close all resources
      @timer.cancel if @timer
    end

    before_close do
      @timer.cancel
      chunk "monkey!\n"
    end

    [200, {'Content-Type' => 'text/plain'}, []]
  end
end

app = Rack::Builder.app do
  use Rack::Stream
  run App.new
end

run app
```

To run the example:

```
> thin start -R config.ru -p 3000
> curl -i -N http://localhost:3000/
>> HTTP/1.1 200 OK
>> Content-Type: text/plain
>> Transfer-Encoding: chunked
>>
>> chunky 0
>> chunky 1
>> chunky 2
>> monkey
```

This same endpoint can be accessed via WebSockets or EventSource, see
'Multi-Protocol Support' below. Full examples can be found in the `examples`
directory.

## Connection Lifecycle

When using rack-stream, downstream apps can access the
`Rack::Stream::App` instance via `env['rack.stream']`. This object is
used to control when the connection is closed, and what is streamed.
`Rack::Stream::DSL` delegates access methods to `env['rack.stream']`
on the downstream rack app.

`Rack::Stream::App` instances are in one of the follow states:

* new
* open
* closed
* errored

Each state is described below.

### new

When a request first comes in, rack-stream processes any downstream
rack apps and uses their status and headers for its response. Any
downstream response bodies are queued for streaming once the headers
and status have been sent. Any calls to `#chunk` before a connection
is opened is queued to be sent after a connection opens.

```ruby
use Rack::Stream

# once Rack::Stream instance is :open, 'Chunky Monkey' will be streamed out
run lambda {|env| [200, {'Content-Type' => 'text/plain'}, ['Chunky Monkey']]}
```

### open

Before the status and headers are sent in the response, they are
frozen and cannot be further modified. Attempting to modify these
fields will put the instance into an `:errored` state.

After the status and headers are sent, registered `:after_open`
callbacks will be called. If no `:after_open` callbacks are defined,
the instance will close the connection after flushing any queued
chunks.

If any `:after_open` callbacks are defined, it's the callback's
responsibility to call `#close` when the connection should be
closed. This allows you to build firehose streaming APIs with full
control of when to close connections.

```ruby
use Rack::Stream

run lambda {|env|
  stream = env['rack.stream']
  stream.after_open do
    stream.chunk "Chunky"
    stream.chunk "Monkey"
    stream.close  # <-- It's your responsibility to close the connection
  end
  [200, {'Content-Type' => 'text/plain'}, ['Hello', 'World']]  # <-- downstream response bodies are also streamed
}
```

There are no `:before_open` callbacks. If you want something to be
done before streaming is started, simply return it as part of your
downstream response.

### closed

An instance enters the `:closed` state after the method `#close` is
called on it. By default, any remainined queued content to be streamed
will be flushed before the connection is closed.

```ruby
use Rack::Stream

run lambda {|env|
  # to save typing, access the Rack::Stream instance with #instance_eval
  env['rack.stream'].instance_eval do
    before_close do
      chunk "Goodbye!"  # chunks can still be sent
    end

    after_close do
      # any additional cleanup. Calling #chunk here will result in an error.
    end
  end
  [200, {}, []]
}
```

### errored

An instance enters the `:errored` state if an illegal action is
performed in one of the states. Legal actions for the different states
are:

* **new** - `#chunk`, `#status=`, `#headers=`
* **open** - `#chunk`, `#close`

All other actions are considered illegal. Manipulating headers after
`:new` is also illegal. The connection is closed immediately, and the
error is written to `env['rack.error']`

## Manipulating Content

When a connection is open and streaming content, you can define
`:before_chunk` callbacks to manipulate the content before it's sent
out.

```ruby
use Rack::Stream

run lambda {|env|
  env['rack.stream'].instance_eval do
    after_open do
      chunk "chunky", "monkey"
    end

    before_chunk do |chunks|
      # return the manipulated chunks of data to be sent
      # this will stream MONKEYCHUNKY
      chunks.map(&:upcase).reverse
    end
  end
}
```

## Multi-Protocol Support

`Rack::Stream` allows you to write an API endpoint that automatically
responds to different protocols based on the incoming request. This
allows you to write a single rack endpoint that can respond to normal
HTTP, WebSockets, or EventSource.

Assuming that rack-stream endpoint is running on port 3000. You can
access it with the following:

### HTTP

```
# -i prints headers, -N immediately displays output instead of buffering
curl -i -N http://localhost:3000/
```

### WebSockets

With Ruby:

```ruby
require 'eventmachine'
require 'faye/websocket'

EM.run {
  socket = Faye::WebSocket::Client.new('ws://localhost:3000/')
  socket.onmessage = lambda {|e| puts e.data}  # puts each streamed chunk
  socket.onclose   = lambda {|e| EM.stop}
}
```

With Javascript:

```js
var socket = new WebSocket("ws://localhost:3000/");
socket.onmessage = function(m) {console.log(m);}
socket.onclose   = function()  {console.log('socket closed');}
```

### EventSource

From Wikipedia:

> Server-sent events is a technology for providing push notifications
> from a server to a browser client in the form of DOM events. The
> Server-Sent Events EventSource API is now being standardized as part
> of HTML5 by the W3C.

With Ruby:

```ruby
require 'em-eventsource'

EM.run do
  source = EventMachine::EventSource.new("http://example.com/streaming")
  source.message do |m|
    puts m
  end
  source.start
end
```

With Javascript:

```js
var source = new EventSource('/');
source.addEventListener('message', function(e) {
  console.log(e.data);
});
```

## Supported Runtimes

* 1.9.2
* 1.9.3

If a runtime is not listed above, it may still work. It just means I
haven't tried it yet. The only app server I've tried running is Thin.

## Roadmap

* more protocols / custom protocols http://en.wikipedia.org/wiki/HTTP_Streaming
* integrate into [grape](http://github.com/intridea/grape)
* add sinatra example that serves page that uses JS to connect
* deployment guide
* better integration with rails

* body: don't enqueue more chunks if state is succeeded?
* performance: GC, cleanup references, profile


## Further Reading

* [API Reference](http://rubydoc.info/gems/rack-stream)
* [Stream Updates With Server-Sent Events](http://www.html5rocks.com/en/tutorials/eventsource/basics/)
* [thin_async](https://github.com/macournoyer/thin_async) was where I got started
* [thin-async-test](https://github.com/phiggins/thin-async-test) used to simulate thin in tests
* [thin](https://github.com/macournoyer/thin)
* [faye-websocket-ruby](https://github.com/faye/faye-websocket-ruby) used for testing and handling different protocols
* [rack-chunked](http://rack.rubyforge.org/doc/Rack/Chunked.html)
