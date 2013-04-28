module Tracker
	
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
				torrent = Tracker::Torrent.new(self, info_hash)
				@torrents[info_hash] = torrent
			end

			torrent
		end

		def purge!
			@torrents = @torrents.reject { |torrent| 
				torrent.purge! 
				torrent.peers.empty?
			}
		end

		def to_hash
			{
				:interval => interval,
				:torrents => torrents.map { |_, torrent| torrent.to_hash }
			}
		end

	end
end
