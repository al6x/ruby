module OS
  def self.say message
    pid = spawn("say \"#{message}\"")
    Process.detach(pid)
  end
end