class ConnectionHandler
  attr_reader :waiting_list
  attr_reader :clients

  def initialize
    @clients = ClientCollection.new
    @waiting_list = ClientCollection.new
  end

  def connect(client)
    waiting_list << Client.new(client)
  end

  def disconnect(client)
    client = find_client(client)
    clients.delete(client)

    send_to_all({method: 'disconnect', data: client.to_hash})
  end

  def ready(client, message)
    client = waiting_list.delete(client)
    clients << client

    message['data'].each do |k,v|
      client.send(:"#{k}=", v)
    end

    location = message['data']['location']
    client.location = GeoKit::GeoLoc.new(lat: location[0], lng: location[1])

    clients.reject { |cl| cl.signature == client.signature }.each do |cl|
      message = {method: 'connect', data: client.to_hash_with_distance(cl.location) }
      cl.connection.send(message.to_json)
    end

    client.connection.send({
            method: 'contact-list',
            data: {
              clients: clients.distance_list(location: client.location, signature: client.signature)
            }
          }.to_json)
  end

  def private_message(from, to, message)
    from = clients.find_by_signature(from.signature)
    to = clients.find_by_id(to.to_s)

    to.connection.send({
        method: 'private-message',
        data: {
          from: from.id,
          from_name: from.name,
          to: to.id,
          to_name: to.name,
          time: Time.now.strftime("%T"),
          message: message
        }
      }.to_json)
  end

  private
  def find_client(client)
    clients.find_by_signature(client.signature)
  end

  def send_to_all(message, all = clients)
    all.each { |cl| cl.connection.send(message.to_json) }
  end

  def send_to_all_but_self(message, client)
    send_to_all(message, clients.reject { |cl| cl.signature == client.signature})
  end
end
