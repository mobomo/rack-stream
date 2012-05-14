require 'faye/websocket'

EM.run {
  ws = Faye::WebSocket::Client.new('ws://localhost:3000/')
  ws.onopen = lambda do |event|
    ws.send("hello world")
  end
  ws.onmessage = lambda do |event|
    puts "message: #{event.data}"
  end
  ws.onclose = lambda do |event|
    puts "websocket closed"
    EM.stop
  end
}