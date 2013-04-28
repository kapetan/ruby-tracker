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
			peer = find_peer(ip, port, id)

			if not peer
				peer = Tracker::Peer.new(self, ip, port, id)
				@peers.push(peer)
			end

			peer
		end

		def find_peer(ip, port, id)
			@peers.find { |p| p.ip == ip and p.port == port and p.id == id }
		end

		def peers(num = nil, ignore_peers = [])
			num ||= @tracker.numwant
			num = @peers.length if num == :all

			@peers.select { |p| !ignore_peers.include?(p) }.sort { rand }[0...num]
		end

		def destroy_peer(ip, port, id)
			peer = find_peer(ip, port, id)
			@peers.delete(peer) if peer

			if @peers.empty?
				tracker.torrents.delete(@info_hash)
			end

			peer
		end

		def to_hash
			{
				:peers => peers.map { |peer| peer.to_hash },
				:created_at => created_at,
				:completed => completed,
				:uncompleted => uncompleted,
				:info_hash => info_hash.to_hex
			}
		end
	end
	
end
