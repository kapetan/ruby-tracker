module Tracker
	class Torrent
		attr_reader :info_hash, :peers, :created_at, :tracker

		def initialize(tracker, info_hash)
			@tracker = tracker
			@info_hash = info_hash
			@peers = []
			@created_at = Time.now
		end

		def ==(torrent)
			torrent.is_a?(Torrent) and torrent.info_hash == @info_hash
		end

		def eql?(torrent)
			torrent.hash == hash
		end

		def hash
			@info_hash.hash
		end

		def completed
			@peers.reduce(0) { |acc, p| acc + (p.completed? ? 1 : 0) }
		end

		def uncompleted
			@peers.reduce(0) { |acc, p| acc + (p.completed? ? 0 : 1) }
		end

		def purge!
			@peers = @peers.reject { |peer| peer.stale? }
		end

		def peer(ip, port, id)
			peer = @peers.find { |p| p.ip == ip and p.port == port and p.id == id }

			if not peer
				peer = Tracker::Peer.new(self, ip, port, id)
				@peers.push(peer)
			end

			peer
		end

		def peers(num = nil, ignore_peers = [])
			num ||= @tracker.numwant
			num = @peers.length if num == :all

			@peers.select { |p| !ignore_peers.include?(p) }.sort { rand }[0...num]
		end

		def to_hash
			{
				:peers => peers.map { |peer| peer.to_hash },
				:created_at => created_at,
				:info_hash => info_hash.to_hex
			}
		end
	end

	class Base
		attr_reader :interval, :numwant, :torrents

		DEFAULT_INTERVAL = 300
		DEFAULT_NUMWANT = 30

		def initialize(options = {})
			@interval = options[:interval] || DEFAULT_INTERVAL
			@numwant = options[:numwant] || DEFAULT_NUMWANT

			@torrents = {}
		end
		
		def torrent(info_hash)
			torrent = @torrents[info_hash]

			if not torrent
				torrent = Torrent.new(self, info_hash)
				@torrents[info_hash] = torrent
			end

			torrent
		end

		def purge!
			@torrents.each_value { |torrent| torrent.purge! }
		end

		def to_hash
			{
				:interval => interval,
				:torrents => Hash[torrents.map { |n,v| [n.to_hex, v.to_hash] }]
			}
		end

	end
end
