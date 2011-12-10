class Client < Struct.new(:connection, :nickname, :location)
  def signature
    connection.signature
  end
end

