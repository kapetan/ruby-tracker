require 'tracker_request_error.rb'
require 'logger'

class RequestValidator
  Parameters = Struct.new(:info_hash, :peer_id, :port, :uploaded,
             :downloaded, :left, :compact, :event, :ip, :numwant)

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.progname = "Tracker"
  end

  def validate(params, ip = nil)
    p = Parameters.new

    param = params[:info_hash]
    if param and param.bytesize == 20
      p.info_hash = param
    else
      error :info_hash, param
    end

    param = params[:peer_id]
    if param and param.bytesize == 20
      p.peer_id = param
    else
      error :peer_id, param
    end

    p.port = i params[:port]
    error :port if not p.port

    param = params[:ip]
    param = ip if not param
    error :ip if not param
    p.ip = param

    p.downloaded = i params[:downloaded]
    error :downloaded if not p.downloaded

    p.uploaded = i params[:uploaded]
    error :uploaded if not p.uploaded

    p.left = i params[:left]
    error :left if not p.left

    p.numwant = i params[:numwant]

    param = params[:event]
    if param and /^started|stopped|completed$/ === param
      p.event = param
    end

    param = i params[:compact]
    p.compact = param == 1

    p
  end

  private
  def i(int)
    if int and /^[\d]+$/ === int
      int.to_i
    else
      nil
    end
  end

  def error(name, value = nil)
    log = value ? ", was '#{value}' with length #{value.bytesize}":""
    @logger.info("#{name} is not valid#{log}")
    raise TrackerRequestError, "#{name} is not valid"
  end

end
