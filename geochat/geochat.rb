require 'eventmachine'
require 'em-websocket'

module GeoChat
  def start_server
    logger.info("Starting reactor...")
    EventMachine.run do
      logger.info("Reactor started!")
      logger.info("Started GeoChat on host %s and port %d" % [GeoChat::Config.host, GeoChat::Config.port])

      EventMachine::WebSocket.start(host: GeoChat::Config.host, port: GeoChat::Config.port) do |ws|
        ws.onopen do
          logger.debug("New connection initiated.")
        end

        ws.onclose do
          logger.debug("Connection closed...")
        end

        ws.onmessage do |msg|
          logger.debug("Received message %s" % msg)
          ws.send "Pong: #{msg}"
        end
      end
    end
  end

  def logger
    GeoChat::Config.logger
  end

  module_function :start_server, :logger
end
