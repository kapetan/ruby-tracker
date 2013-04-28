$LOAD_PATH << File.dirname(__FILE__)

require 'tracker/torrent'
require 'tracker/base'
require 'tracker/request'
require 'tracker/response'
require 'tracker/peer'

require 'tracker/bencode/error'
require 'tracker/bencode/bencoder'
require 'tracker/bencode/bdecoder'

require 'rubygems'
require 'sinatra'
require 'haml'
require 'json'
require 'logger'
require 'socket'

options = {
	:port => settings.port,
	:dump_errors => true,
	:show_exceptions => true
}

set :logging, false
set :show_exceptions, options[:show_exceptions]
set :dump_errors, options[:dump_errors]
set :port, options[:port]
set :root, File.join(File.dirname(__FILE__), '..', 'assets')

def usage(options)
	options[:ip] = UDPSocket.open { |s| s.connect('64.233.187.99', 1); s.addr.last }
	puts "== A Ruby Tracker with backup from Sinatra"
	puts "url: http://#{options[:ip]}:#{options[:port]}/announce"
	puts ""
end

usage(options)

helpers do
	def size(size)
		units = ['B', 'KB', 'MB', 'GB', 'TB']
		i = 0

		while size >= 1024 and i < units.length do
			size /= 1024
			i += 1
		end

		"#{size.round(2)} #{units[i]}"
	end
end

tracker = Tracker::Base.new

get '/' do
	erb :index, :locals => { 
		:announce_url => "http://#{options[:ip]}:#{options[:port]}/announce",
		:tracker => tracker.to_hash
	}
end

post '/' do
	torrent = JSON.parse(request.body.read)
	torrent['info_hash'] = Tracker::BinaryString.from_hex(torrent['info_hash'])

	peer = torrent['peer']
	peer['id'] = Tracker::BinaryString.from_hex(peer['id'])
	peer['port'] = peer['port'].to_i

	torrent = tracker.torrents[torrent['info_hash']]
	peer = torrent.destroy_peer(peer['ip'], peer['port'], peer['id'])

	peer ? peer.to_hash.to_json : 'null'
end

get '/announce' do
	content_type 'text/plain', :charset => 'utf-8'

	begin
		parameters = { :ip => request.ip }.update(params)
		request = Tracker::Request.new(parameters)

		request.valid!
		
		torrent = tracker.torrent(request.info_hash)
		peer = torrent.peer(request.ip, request.port, request.peer_id)

		peer.update(request)

		response = Tracker::AnnounceResponse.new(torrent)
		response.bencode({ :ignore_peers => [peer] }.update(request))
	rescue Tracker::Request::Error => err
		status 400
		err.bencode
	end
end
