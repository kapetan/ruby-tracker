module Tracker
	class Peer
		attr_reader :ip, :port, :id, :updated_at, :events
		attr_accessor :left, :uploaded, :downloaded

		TIMEOUT = 600

		def initialize(torrent, ip, port, id)
			@torrent = torrent
			@ip = ip
			@port = port
			@id = id

			@events = []
			@uploaded = 0
			@downloaded = 0
			@left = 0
			
			@updated_at = Time.now
		end

		def ==(peer)
			peer.is_a?(Peer) and peer.ip == @ip and peer.port == @port and peer.id == @id
		end

		def completed?
			@left.zero?
		end

		def stale?
			Time.now - @updated_at > @torrent.tracker.interval
		end

		def update(params)
			@uploaded = params[:uploaded]
			@downloaded = params[:downloaded]
			@left = params[:left]
			@events.push(params[:event]) if params[:event]

			@updated_at = Time.now
		end

		def to_hash
			{
				:ip => ip,
				:port => port,
				:id => id.to_hex,
				:updated_at => updated_at,
				:completed => completed?,
				:downloaded => downloaded,
				:uploaded => uploaded,
				:left => left
			}
		end
	end
end
