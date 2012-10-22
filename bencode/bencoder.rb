$LOAD_PATH << File.dirname(__FILE__)
require 'bencode_error.rb'

class BEncoder
  def encode(obj)
    case obj
    when String then
      "#{obj.bytesize}:#{obj}"
    when Symbol then
      self.encode obj.to_s
    when Fixnum, Bignum then
      "i#{obj}e"
    when Array then
      items = ""
      obj.each {|item| items += self.encode(item)}
      "l#{items}e"
    when Hash then
      items = ""
      obj.each_pair do |key, value|
        raise BencodeError, "Keys in hash must be of type String or Symbol" if key.class != String and key.class != Symbol
        items += self.encode(key) + self.encode(value)
      end
      "d#{items}e"
    else
      raise BencodeError, "Cannot encode type #{obj.class}"
    end
  end
end
