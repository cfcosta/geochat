class Client < Struct.new(:connection, :id, :name, :location, :link, :picture)
  def to_hash
    {
      id: id,
      nickname: name,
      location: location.to_a,
      link: link,
      picture: picture
    }
  end

  def to_hash_with_distance(original_loc)
    {
      id: id,
      nickname: name,
      distance: original_loc.distance_to(location),
      link: link,
      picture: picture
    }
  end

  def signature
    connection.signature
  end
end

