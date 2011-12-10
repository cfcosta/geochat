require 'json'
require 'eventmachine'
require 'em-websocket'
require 'geokit'

$:.unshift('.', File.dirname(__FILE__))
require 'models/client'
require 'models/client_collection'

module GeoChat
  def start_server
    logger.info("Starting reactor...")
    EventMachine.run do
      logger.info("Reactor started!")
      logger.info("Started GeoChat on host %s and port %d" % [GeoChat::Config.host, GeoChat::Config.port])

      @connected_clients = ClientCollection.new

      EventMachine::WebSocket.start(host: GeoChat::Config.host, port: GeoChat::Config.port) do |ws|
        ws.onopen do
          client = Client.new(ws)
          @connected_clients << client

          logger.debug("New connection initiated.")
          logger.debug("Connected clients: #{@connected_clients.map(&:nickname)}")

          @connected_clients.reject { |x| x.signature == client.signature }.each do |c|
            c.connection.send({method: 'connect', data: {nickname: client.nickname}}.to_json)
          end
        end

        ws.onclose do
          client = @connected_clients.find_by_signature(ws.signature)

          @connected_clients.delete(ws)
          @connected_clients.each do |c|
            c.connection.send({method: 'disconnect', data: {nickname: client.nickname}}.to_json)
          end
          logger.debug("Connection closed...")
          logger.debug("Connected clients: #{@connected_clients.map(&:nickname)}")
        end

        ws.onmessage do |msg|
          logger.debug("Received message %s" % msg)

          message = JSON.parse(msg)
          client = @connected_clients.find_by_signature(ws.signature)
          case message['method']
          when 'nickname'
            logger.debug("Changing %s nickname to %s" % [client.nickname.inspect, message['data']['nickname']])

            @connected_clients.reject { |x| x.signature == client.signature }.each do |c|
              c.connection.send({method: 'nickname_change', data: {before: client.nickname, nickname: message['data']['nickname']}}.to_json)
            end

            client.nickname = message['data']['nickname']
          when 'location'
            logger.debug("Changing %s location to %s" % [client.nickname.inspect, message['data']['location']])
            location = message['data']['location']
            client.location = GeoKit::GeoLoc.new(lat: location[0], lng: location[1])

            @connected_clients.reject { |x| x.signature == client.signature }.each do |c|
              c.connection.send({method: 'location_change', data: {nickname: client.nickname, distance: c.location.distance_to(client.location) }}.to_json)
            end
          when 'client_list'
            logger.debug("Sending client list to %s" % client.nickname.inspect)
            users = @connected_clients.distance_list(location: client.location, signature: client.signature)
            ws.send({method: 'client_list', data: {users: users}}.to_json)
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
