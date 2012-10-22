$LOAD_PATH << File.dirname(__FILE__)
require 'tracker.rb'
require 'tracker_request_error.rb'
require 'bencode/bencoder.rb'
require 'request_validator.rb'

require 'rubygems'
require 'sinatra'
require 'haml'
require 'json'

require 'socket'

options = {
  :port => settings.port,
  :dump_errors => true,
  :show_exceptions => true
}

usage = Proc.new do
  options[:ip] = UDPSocket.open { |s|
    s.connect('64.233.187.99', 1); s.addr.last }
  puts "== A Ruby Tracker with backup from Sinatra"
  puts "url: http://#{options[:ip]}:#{options[:port]}/announce"
  puts ""
end

usage.call

tracker = Tracker.new
bencoder = BEncoder.new
valid = RequestValidator.new

set :show_exceptions, options[:show_exceptions]
set :dump_errors, options[:dump_errors]
set :port, options[:port]

get '/' do
  haml :index, :locals => {
    :announce_url => "http://#{options[:ip]}:#{options[:port]}/announce"}
end

get '/announce' do
  begin
    p = valid.validate params, request.ip

    peer = tracker.peer p.info_hash, p.ip, p.port, p.peer_id
    tracker.update_peer peer, p.downloaded, p.uploaded, p.left, p.event
    peer_list = tracker.peer_list p.info_hash, p.numwant, peer

    stats = tracker.stats p.info_hash

    response = {
      :interval => Tracker::INTERVAL,
      :complete => stats[:complete],
      :incomplete => stats[:incomplete],
      :peers => []
    }

    peer_list.each do |peer|
      response[:peers].push({:peer_id => peer.id, :ip => peer.ip,
                              :port => peer.port})
    end

    content_type 'text/plain', :charset => 'utf-8'
    bencoder.encode response
  rescue TrackerRequestError => err
    content_type 'text/plain', :charset => 'utf-8'
    bencoder.encode 'failure reason' => err.message
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
