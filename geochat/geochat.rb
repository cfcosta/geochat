require 'eventmachine'
require 'em-websocket'

module GeoChat
  def start_server
    EventMachine.run do
      EventMachine::WebSocket.start(host: GeoChat::Config.host, port: GeoChat::Config.port) do |ws|
        ws.onopen do
          puts "WebSocket connection open"

          # publish message to the client
          ws.send "Hello Client"
        end

        ws.onclose do
          puts "Connection closed"
        end

        ws.onmessage do |msg|
          puts "Recieved message: #{msg}"
          ws.send "Pong: #{msg}"
        end
      end
    end
  end

  module_function :start_server
end
