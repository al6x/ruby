require 'base'
require 'CGI'
require 'uri'

class Url
  attr_reader :path, :query, :scheme, :host, :port, :absolute

  def initialize path, query, scheme = nil, host = nil, port = nil
    @path = path.sub(/\/$/, "") # removing trailing /
    @query = query.reject{|k, v| k.empty?}
    @absolute = not(host.empty? and port.nil? and scheme.empty?)
    @host, @port, @scheme = host, port, scheme if @absolute
  end

  def absolute?; @absolute end

  def self.parse_querystring qs
    query = {}
    CGI::parse(qs).reject{|k, v| k.empty? or v.empty? }.each{|k, v| query[k] = v[0] }
  end

  def self.parse urlstring
    uri = URI.parse urlstring
    Url.new uri.path, Url.parse_querystring(uri.query), uri.scheme, uri.host, uri.port
  end

  def self.from_rack env
    Url.new(
      env['REQUEST_PATH'], Url.parse_querystring(env['QUERY_STRING']),
      env['rack.url_scheme'], env['HTTP_HOST'], env['SERVER_PORT']
    )
  end

  def inspect; to_s end

  def to_s
    querystring = @query
      .inject([]){|l, kv| l << "#{CGI.escape(kv[0])}=#{kv[1]}"}
      .join('&')
    pathinfo = "#{@path}#{querystring.empty? ? '' : '?' }#{querystring}"
    if absolute?
      "#{scheme}://#{host}#{port != 80 ? ':' + port : '' }#{pathinfo}"
    else
      pathinfo
    end
  end
end


if __FILE__ == $0
  u = Url.parse("http://host.com/path?a=b&c=d")
  p u
  p u.query
  p u.path
end