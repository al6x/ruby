require 'rack'
require 'thin'
require 'faye/websocket'
require 'json'

require 'base'
require_relative 'helpers'
require_relative 'url'


class Session
  include Logging
  attr_reader :id, :app, :log

  @@next_id = 0
  def initialize
    @id = (@@next_id += 1)
  end

  def on event
    event
  end
end


class Server
  include Logging
  @@server_assets_path = File.expand_path(File.dirname(__FILE__) + '/assets')

  def initialize port: 8080, host: "127.0.0.1", asset_paths: [], asset_prefix: '/_assets'
    @port, @host, @asset_paths, @asset_prefix = port, host, asset_paths, asset_prefix
    @log = Log.new 'HTTP'
  end

  def build_handler
    assets_handler = Rack::Assets.new([@@server_assets_path] + @asset_paths, @asset_prefix)

    lambda do |env|
      url = Url.from_rack env
      case
      when Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, ['irc', 'xmpp'], ping: 5 )
        session = Session.new
        session.info :created

        ws.onmessage = lambda do |event|
          data = JSON.parse event.data
          session.info '<<', data
          result = session.on data
          session.info '>>', result
          ws.send JSON.generate(result)
        end

        ws.onclose = lambda do |event|
          session.info :close
          session = nil
          ws = nil
        end

        ws.onerror = lambda do |event|
          session.error :error, event
        end

        ws.rack_response
      when assets_handler.match?(url.path)
        assets_handler.call env
      else
        handle env
      end
    end
  end

  def handle env
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
  Server.new.run
end