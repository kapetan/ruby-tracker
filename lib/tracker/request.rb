module Tracker
	class BinaryString < String
		def self.from_hex(str)
			(str.length / 2).floor.times.map { |i| str[i * 2, 2].hex }.pack('C*')
		end

		def to_hex
			unpack('C*').map {|b| (b < 16 ? '0' : '') + b.to_s(16)}.join('')
		end
	end

	class Request
		class Error < StandardError
			attr_reader :parameter

			def initialize(parameter, message)
				super(message)
				@parameter = parameter
			end

			def bencode
				Tracker::Bencode.encode('failure reason' => message)
			end
		end

		PARAMETERS = [:info_hash, :peer_id, :port, :downloaded, :uploaded, :left,
			:compact, :no_peer_id, :event, :ip, :numwant, :key]

		attr_reader *PARAMETERS

		def initialize(parameters)
			PARAMETERS.each { |name| instance_variable_set :"@#{name}", (parameters[name.to_sym] || parameters[name.to_s]) }
		end

		def [](name)
			respond_to?(name) ? send(name) : nil
		end

		def errors
			return @errors if @errors

			@errors = []

			error(:info_hash) if @info_hash.nil? or @info_hash.bytesize != 20
			error(:peer_id) if @peer_id.nil? or @peer_id.bytesize != 20
			error(:port) if @port.nil? or not @port.match(/^\d+$/)
			error(:ip) if @ip.nil?
			error(:downloaded) if @downloaded.nil? or not @downloaded.match(/^\d+$/)
			error(:uploaded) if @uploaded.nil? or not @uploaded.match(/^\d+$/)
			error(:left) if @left.nil? or not @left.match(/^\d+$/)
			error(:event) if @event and not @event.match(/^started|stopped|completed$/)
			error(:numwant) if @numwant and not @numwant.match(/^\d+$/)
			error(:compact) if @compact and not @compact.match(/0|1/)

			@errors
		end

		def info_hash
			BinaryString.new(@info_hash)
		end

		def peer_id
			BinaryString.new(@peer_id)
		end

		def valid?
			errors.length.zero?
		end

		def valid!
			err = errors.first
			raise err if err
		end

		def port
			@port.to_i
		end

		def downloaded
			@downloaded.to_i
		end

		def uploaded
			@uploaded.to_i
		end

		def left
			@left.to_i
		end

		def numwant
			@numwant && @numwant.to_i
		end

		def compact
			(@compact || 0).to_i
		end

		def compact?
			compact == 1
		end

		def no_peer_id?
			!!@no_peer_id
		end

		def to_hash
			Hash[PARAMETERS.map { |name| [name, send(name)] }]
		end

		private

		def error(parameter, message = nil)
			message = 'Invalid parameter %s' % [parameter.to_s] if message.nil?
			@errors.push(Error.new(parameter, message))
		end
	end

end
