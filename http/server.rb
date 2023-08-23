require 'base'
require 'rack'
require 'thin'
require 'faye/websocket'
require 'json'
require 'base'
require_relative 'helpers'
require_relative 'url'
require_relative 'page'

class Server
  include Logging
  @@server_assets_path = File.expand_path(File.dirname(__FILE__) + '/assets')

  def initialize page_class:, port: 8080, host: "127.0.0.1", asset_paths: [], asset_prefix: '/_assets'
    @page_class = page_class
    @port, @host, @asset_paths, @asset_prefix = port, host, asset_paths, asset_prefix
    @log = Log.new 'HTTP'
  end

  def build_handler
    assets_handler = Rack::Assets.new([@@server_assets_path] + @asset_paths, @asset_prefix)

    lambda do |env|
      method, url = env['REQUEST_METHOD'].downcase, Url.from_rack(env)
      case
      when Faye::WebSocket.websocket?(env)
        build_socket_handler env, url
      when assets_handler.match?(url.path)
        assets_handler.call env
      else
        handle_rest method, url.path, url.query
      end
    end
  end

  def build_socket_handler env, url
    ws = Faye::WebSocket.new(env, ['irc', 'xmpp'], ping: 5 )

    app = @page_class.build url.host, url.path_parts, url.query
    page = @page_class.new app
    page.info :created

    process_and_send = lambda do
      outbox = page.process
      outbox.each do |res|
        page.info '>>', res
        ws.send JSON.generate(res)
      end
    end

    path_req = { path: url.path_parts, query: url.query }
    page.info '<<', path_req
    page.inbox << path_req
    process_and_send.call

    ws.onmessage = lambda do |event|
      req = JSON.parse(event.data).symbolize_keys
      unless req.include? :tick
        page.info '<<', req
        page.inbox << req
      end
      process_and_send.call
    end

    ws.onclose = lambda do |event|
      page.info :close
      page = nil
      ws = nil
    end

    ws.onerror = lambda do |event|
      page.error :error, event
    end

    ws.rack_response
  end

  def handle_rest method, path, query
    page = File.read "#{@@server_assets_path}/page.html"
    [200, { 'Content-Type': 'text/html' }, [page]]

    # error :unknown, path: path
    # [404, {}, ["Unknown request"]]
  end

  def run
    Faye::WebSocket.load_adapter 'thin'

    thin = Rack::Handler.get 'thin'
    Thin::Logging.silent = true

    info :started, port: @port
    thin.run build_handler, Port: @port, Host: @host
  end
end


if __FILE__ == $0
  Server.new(page_class: Page).run
end