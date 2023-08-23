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

  def path_parts
    @path.split("/").reject{|v| v.empty?}
  end

  def self.parse_querystring qs
    query = {}
    CGI::parse(qs).each{|k, v| query[k.to_sym] = v[0] }
    query.reject!{|k, v| k.empty? or v.empty? }
    query
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
      .inject([]){|l, kv| l << "#{CGI.escape(kv[0].to_s)}=#{kv[1]}"}
      .join('&')
    pathinfo = "#{@path}#{querystring.empty? ? '' : '?' }#{querystring}"
    if absolute?
      "#{scheme}://#{host}#{port != 80 ? ':' + port : '' }#{pathinfo}"
    else
      pathinfo
    end
  end
end


test :url do
  u = Url.parse("http://host.com/path?a=b&c=d")
  u.to_s.should == "http://host.com/path?a=b&c=d"
  u.query.should == { a: 'b', c: 'd' }
  u.path.should == '/path'
  u.path_parts.should == ['path']

  u = Url.parse("http://host.com/?a=")
  u.path.should == ''
  u.query.should == {}
end