require_relative 'terminal'

class Log
  Message = Struct.new :level, :module, :id, :message, :data

  @emitters = []
  class << self
    attr_accessor :emitters

    def emit message
      @emitters.each { |e| e.emit message }
    end

    [:debug, :info, :warning, :error].each do |level|
      define_method level do |message, data = {}|
        Log.emit Message.new(level, nil, nil, message.to_s, data)
      end
    end
  end

  def initialize object_or_module_name, id = nil
    case object_or_module_name
    when String
      @module, @id = object_or_module_name, id
    else
      @module = object_or_module_name.class.to_s.split("::").last
      id = object_or_module_name.id if object_or_module_name.respond_to? :id
    end
    @id = id.to_s unless id.nil?
  end

  def id id
    @id = id
    self
  end

  [:debug, :info, :warning, :error].each do |level|
    define_method level do |message, data = {}|
      Log.emit Message.new(level, @module, @id, message.to_s, data)
    end
  end

  class TerminalEmitter
    def initialize
      @disabled = ENV.fetch("disable_logs", "").split(",").to_set
    end

    def emit message
      return if @disabled.include?(message.module) or @disabled.include?(message.level)

      fmodule = (message.module || '').downcase[0..3].ljust(4)
      fid = (message.id || '')[0..6].ljust(7)

      line = fmodule + " | " + fid + " " + message.message

      line = case message.level
      when :debug
        Terminal.grey "  " + line
      when :info
        "  " + line
      when :warning
        Terminal.yellow "W " + line
      when :error
        Terminal.red "E " + line
      else
        raise "unknown"
      end
      $stdout << line


      def indent s
        indent = "                 "
        indent + s.gsub("\n", indent)
      end

      data = message.data
      if data.is_a? RuntimeError
        $stdout << "\n" + Terminal.red(indent data.message)
        $stdout << "\n" + Terminal.grey(indent data.backtrace.join("\n"))
      elsif not data.empty?
        s = data.inspect.gsub(/^\{|\}$/, '')
        if s.size < 50
          $stdout << " " + Terminal.grey(s)
        else
          $stdout << "\n" + Terminal.grey(indent s)
        end
      end

      $stdout << "\n"
      $stdout.flush
    end
  end
end

module Logging
  [:debug, :info, :warning, :error].each do |level|
    define_method level do |message, data = {}|
      (@log || Log.new(self)).send level, message.to_s, data
    end
  end
end

Log.emitters << Log::TerminalEmitter.new

if __FILE__ == $0
  log = Log.new "Finance"
  log.id("MSFT").info "getting prices in USD"
  log.id("MSFT").info "getting prices in USD", price: 100
  log.id("MSFT").warning "no response"
  begin
    raise "some error"
  rescue => e
    log.id("MSFT").error("can't get price", e)
  end
end