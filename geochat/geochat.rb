require 'json'
require 'eventmachine'
require 'em-websocket'
require 'geokit'

$:.unshift('.', File.dirname(__FILE__))
require 'models/client'
require 'models/client_collection'
require 'models/connection_handler'

module GeoChat
  def start_server
    EventMachine.run do
      @handler = ConnectionHandler.new

      EventMachine::WebSocket.start(host: GeoChat::Config.host, port: GeoChat::Config.port) do |ws|
        ws.onopen do
          logger.debug("Client connected!")
          @handler.connect(ws)
        end

        ws.onclose do
          logger.debug("Client disconnected!")
          @handler.disconnect(ws)
        end

        ws.onmessage do |msg|
          logger.debug("Received message %s" % msg)
          message = JSON.parse(msg)
          case message['method']
          when 'ready'
            @handler.ready(ws, message)
          when 'private-message'
            @handler.private_message(ws, message['data']['to'], message['data']['text'])
          end
        end
      end
    end
  end

  def logger
    GeoChat::Config.logger
  end

  module_function :start_server, :logger
end
