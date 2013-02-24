$LOAD_PATH << File.dirname(__FILE__)

require 'tracker/base'
require 'tracker/request'
require 'tracker/response'
require 'tracker/peer_id'
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
	options[:ip] = UDPSocket.open { |s|
		s.connect('64.233.187.99', 1); s.addr.last }
	puts "== A Ruby Tracker with backup from Sinatra"
	puts "url: http://#{options[:ip]}:#{options[:port]}/announce"
	puts ""
end

usage(options)

tracker = Tracker::Base.new

get '/' do
	haml :index, :locals => {
		:announce_url => "http://#{options[:ip]}:#{options[:port]}/announce"}
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

get '/stats' do
	haml :stats, :locals => tracker.to_hash  #stats.call
end

=begin
stats = Proc.new do
	s = {
		:global_stats => tracker.global_stats,
		:started => tracker.started,
		:uptime => ((Time.now - tracker.started) / 60).round,
		:updated => tracker.updated
	}

	#global = tracker.global_stats
	#global[:info_hashes].map! {|h| h.to_hex}
	#s[:global_stats] = global
	s
end

get '/stats' do
	haml :stats, :locals => stats.call
end

get '/stats/peer_list' do
	content_type :json
	info_hash = params[:info_hash]

	if info_hash
		plist = tracker.peer_list info_hash.to_bin_from_hex
		plist ? plist.to_json : [].to_json
	else
		[].to_json
	end
end

get '/stats/global' do
	content_type :json
	updated = params[:updated]
	resp = stats.call

	if /[\d]+/ === updated and updated.to_i == tracker.updated
		resp[:global_stats].delete :info_hashes
		resp.to_json
	else
		resp.to_json
		#stats.call.to_json
	end
end
=end
