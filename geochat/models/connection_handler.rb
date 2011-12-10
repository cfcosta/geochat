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

    send_to_all_but_self({method: 'connect', data: client.to_hash}, client)
    client.connection.send({method: 'contact-list',
                            data:
                              {clients: clients.distance_list(location: client.location, signature: client.signature)}
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
