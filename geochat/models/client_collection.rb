class ClientCollection < Array
  def distance_list(options)
    result = reject { |x| x.signature == options[:signature] }
    result.map do |client|
      next unless client.location

      {nickname: client.nickname,
       distance: client.location.distance_to(options[:location])}
    end.compact
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
