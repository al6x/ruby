require 'base'
require_relative 'app'

class Page
  include Logging
  attr_reader :id, :app, :log, :inbox

  @@next_id = 0
  def initialize app
    @app, @inbox = app, []
    @id = (@@next_id += 1)
  end

  def process
    outbox = inbox.map{|event| app.handle event }.flatten
    inbox.clear
    outbox
  end

  def self.build host, path, params
    App.new
  end
end