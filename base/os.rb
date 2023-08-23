module OS
  def self.say message
    pid = spawn "say \"#{message}\""
    Process.detach pid
  end
end

if __FILE__ == $0
  OS.say "hi"
end