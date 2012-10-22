require 'rubygems'
require 'json'

class String
  def to_hex
    self.unpack('C*').
      map {|b| (b < 16 ? '0' : '') + b.to_s(16)}.join('')
  end

  def to_bin_from_hex
    a = []
    for i in (0...(self.bytesize / 2)) do
      a << self[i*2, 2]
    end

    a.map! {|h| h.hex}
    a.pack("C*")
  end
end

class Peer
  attr_reader :ip, :port, :id, :last_contact, :last_event, :hex_id
  attr_accessor :left, :uploaded, :downloaded

  TIMEOUT = 600

  def initialize(ip, port, id)
    @ip = ip
    @port = port
    @id = id
    @hex_id = id.to_hex
    # @hex_id = id.unpack('C*').
    #  map {|b| (b < 16 ? '0' : '') + b.to_s(16)}.join('')

    @uploaded = 0
    @downloaded = 0
    @last_contact = Time.now
    @completed = false
  end

  def ==(peer)
    peer.ip == @ip and peer.port == @port and peer.hex_id == @hex_id
  end

  def last_event=(event)
    @last_event = event
    @completed = true if event == 'complete'
  end

  def completed?
    @completed
  end

  def stale?
    Time.now - @last_contact > TIMEOUT
  end

  def refresh
    @last_contact = Time.now
  end

  def to_json(*a)
    {
      :description => "#{hex_id}@#{ip}:#{port}",
      :last_contact => last_contact,
      :completed => completed?
    }.to_json(*a)
  end

end
