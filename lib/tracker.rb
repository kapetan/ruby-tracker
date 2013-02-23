$LOAD_PATH << File.dirname(__FILE__)

require 'tracker/peer'
require 'tracker/base'
require 'tracker/request'
#require 'tracker/tracker_request_error.rb'
#require 'tracker/request_validator.rb'

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
#bencoder = BEncoder.new
#valid = RequestValidator.new

get '/' do
	haml :index, :locals => {
		:announce_url => "http://#{options[:ip]}:#{options[:port]}/announce"}
end

get '/announce' do
	content_type 'text/plain', :charset => 'utf-8'

	begin
		#p = valid.validate params, request.ip

		#peer = tracker.peer p.info_hash, p.ip, p.port, p.peer_id
		#tracker.update_peer peer, p.downloaded, p.uploaded, p.left, p.event
		#peer_list = tracker.peer_list p.info_hash, p.numwant, peer

		#stats = tracker.stats p.info_hash

		parameters = { :ip => request.ip }.update(params)
		request = Tracker::Request.new(parameters)

		request.valid!

		peer = tracker.peer(request.info_hash, request.ip, request.port, request.peer_id)
		tracker.update_peer(peer, request.downloaded, request.uploaded, request.left, request.event)
		peer_list = tracker.peer_list(request.info_hash, request.numwant, peer)

		stats = tracker.stats(request.info_hash)

		response = {
			:interval => Tracker::Base::INTERVAL,
			:complete => stats[:complete],
			:incomplete => stats[:incomplete],
			:peers => []
		}

		peer_list.each do |peer|
			response[:peers].push({:peer_id => peer.id, :ip => peer.ip, :port => peer.port})
		end

		Tracker::Bencode.encode response
	rescue Tracker::Request::Error => err
		#content_type 'text/plain', :charset => 'utf-8'
		#Tracker::Bencode.encode 'failure reason' => err.message

		err.bencode
	end
end

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
