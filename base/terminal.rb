module Terminal
  class << self
    def green s;  "\e[32m#{s}\e[0m" end
    def grey s;   "\e[90m#{s}\e[0m" end
    def yellow s; "\e[33m#{s}\e[0m" end
    def red s;    "\e[31m#{s}\e[0m" end
  end
end