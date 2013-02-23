#require 'peer.rb'

module Tracker
	class Base
		attr_reader :started, :updated

		INTERVAL = 300

		def initialize
			@peers = BinHash.new
			# @peers = {}
			@started = Time.now
		end

		def global_stats
			active_peers = 0
			active_files = @peers.length

			@peers.each_pair do |info_hash, peers|
				active_peers += peers.length
			end

			{
				:active_peers => active_peers,
				:active_files => active_files,
				:info_hashes => @peers.keys.dup
			}
		end

		def stats(info_hash)
			peers = @peers[info_hash]
			if peers
				completed = 0
				downloaded = 0
				uploaded = 0

				peers.each do |peer|
					completed += 1 if peer.completed?
					downloaded += peer.downloaded
					uploaded += peer.uploaded
				end

				{
					:complete => completed,
					:incomplete => peers.length - completed,
					:downloaded => downloaded,
					:uploaded => uploaded

				}
			else
				nil
			end
		end

		def peer(info_hash, ip, port, id)
			@peers[info_hash] = [] if not @peers[info_hash]

			peer = @peers[info_hash].find {|p| p.id == id and p.ip == ip and
				p.port == port}
			if not peer
				peer = Peer.new ip, port, id
				@peers[info_hash].push peer
				update
			end

			peer
		end

		def update_peer(peer, downloaded, uploaded, left, event)
			peer.downloaded = downloaded
			peer.uploaded = uploaded
			peer.left = left
			peer.last_event = event if event
			peer.refresh
			update
		end

		def peer_list(info_hash, num = nil, ignore_peer = nil)
			num = 50 if not num
			peers = @peers[info_hash]
			return [] if not peers or peers.empty?

			peers = peers.dup
			peers.delete ignore_peer if ignore_peer

			if num == :all or peers.length <= num
				peers
			else
				peers = peers.sort {rand}
				peers[0..(num - 1)]
			end
		end

		private
		def update
			@updated = Time.now.to_i
		end

		class BinHash < Hash
			def [](key)
				super(key.to_hex)
			end

			def []=(key, value)
				super(key.to_hex, value)
			end
		end

	end
end
