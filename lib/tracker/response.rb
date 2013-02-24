module Tracker
	class AnnounceResponse
		def initialize(torrent)
			@torrent = torrent
		end

		def bencode(options = {})
			peers = @torrent.peers(options[:numwant], options[:ignore_peers] || [])

			if options[:compact] == 1
				peers = peers.map do |peer|
					ip = peer.ip.split('.').map { |i| i.to_i }.pack('C*')
					port = [peer.port].pack('n')

					ip + port
				end

				peers = peers.join('')
			else
				peers = peers.map do |peer|
					result = { :ip => peer.ip, port: peer.port }
					result[:peer_id] = peer.id if not options[:no_peer_id]

					result
				end
			end

			Tracker::Bencode.encode({
				:interval => @torrent.tracker.interval, 
				:complete => @torrent.completed, 
				:incomplete => @torrent.uncompleted,
				:peers => peers
			})
		end
	end
end
