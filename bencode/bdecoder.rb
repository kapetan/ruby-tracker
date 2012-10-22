$LOAD_PATH << File.dirname(__FILE__)
require 'bencode_error.rb'

class String
  def shift!
    c = self.chars.first
    self.slice!(0)
    c
  end
end

class BDecoder

  def decode(str)
    decode!(str.dup, 0)
  end

  private
  def decode!(str, at)
    c = str.shift!

    case c
    when /\d/ then
      length = ""
      while c != ':'
        length += c

        str_error("char '#{c}' encountered in length",
                  at) {not (/\d/ === c)}

        c = str.shift!
        at += 1
        str_error("expected ':'", at) {not c}
      end

      length = length.to_i
      str_error("length does not match", at) {length > str.length}

      str.slice!(0, length)
    when 'i' then
      int = ""
      c = str.shift!
      at += 1
      while c != 'e'
        int_error("expected 'e'", at) {not c}
        int_error("char '#{c}' encountered", at) {not (/\d/ === c)}

        int += c
        c = str.shift!
        at += 1
      end

      int_error("can't be empty", at) {int.empty?}
      int.to_i
    when 'l' then
      list = []
      c = str.chars.first
      while c != 'e'
        list_error("expected 'e'", at) {not c}

        len = str.length
        list << decode!(str, at)
        at += (len - str.length)

        c = str.chars.first
      end

      str.shift!
      at += 1
      list
    when 'd' then
      dict = {}
      c = str.chars.first
      while c != 'e'
        dict_error("expected 'e'", at) {not c}

        len = str.length
        key = decode!(str, at)
        at += (len - str.length)

        dict_error("key is of type " + key.class.to_s +
          " (must be string)", at) {key.class != String}

        len = str.length
        dict[key] = decode!(str, at)
        at += (len - str.length)

        c = str.chars.first
      end

      str.shift!
      dict
    else
      error "Cannot parse char '#{c}'", at
    end

  end

  def dict_error(reason, at)
    error("Invalid dictionary, " + reason, at) if yield
  end

  def list_error(reason, at)
    error("Invalid list, " + reason, at) if yield
  end

  def int_error(reason, at)
    error("Invalid integer, " + reason, at) if yield
  end

  def str_error(reason, at)
    error("Invalid byte string, " + reason, at) if yield
  end

  def error(msg, at)
    raise BencodeError, msg + " at position #{at}"
  end

end
