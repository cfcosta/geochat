require 'json'
require 'eventmachine'
require 'em-websocket'
require 'geokit'

class ClientCollection < Array
  def distance_list(options)
    result = reject { |x| x.signature == options[:signature] }
    result.map { |x| {nickname: x.nickname, distance: x.location.distance_to(options[:location])} }
  end

  def delete(connection)
    super(find_by_signature(connection.signature))
  end

  def method_missing(method, *args, &block)
    match = method.to_s.match(/^find_by_(.*)/)
    if match
      find { |x| x.send(match[1].to_sym) == args.first }
    else
      super
    end
  end
end

class Client < Struct.new(:connection, :nickname, :location)
  def signature
    connection.signature
  end
end

module GeoChat
  def start_server
    logger.info("Starting reactor...")
    EventMachine.run do
      logger.info("Reactor started!")
      logger.info("Started GeoChat on host %s and port %d" % [GeoChat::Config.host, GeoChat::Config.port])

      @connected_clients = ClientCollection.new

      EventMachine::WebSocket.start(host: GeoChat::Config.host, port: GeoChat::Config.port) do |ws|
        ws.onopen do
          @connected_clients << Client.new(ws)
          logger.debug("New connection initiated.")
          logger.debug("Connected clients: #{@connected_clients.map(&:nickname)}")
        end

        ws.onclose do
          @connected_clients.delete(ws)
          @connected_clients.each { |client| client.connection.send "A client has disconnected!" }
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
            client.nickname = message['data']['nickname']
          when 'location'
            logger.debug("Changing %s location to %s" % [client.nickname.inspect, message['data']['location']])
            location = message['data']['location']
            client.location = GeoKit::GeoLoc.new(lat: location[0], lng: location[1])
          when 'client_list'
            logger.debug("Sending client list to %s" % client.nickname.inspect)
            distances = @connected_clients.distance_list(location: client.location, signature: client.signature)
            ws.send(distances.to_json)
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
