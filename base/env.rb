module ENVExtensions
  def test? name = nil
    ENV['test'] == 'true' or ENV['test'] == name.to_s
  end
end
ENV.extend ENVExtensions

ARGV.each do |k|
  k, v = k.split(/=/)
  ENV[k] = v || 'true'
end

if __FILE__ == $0
  p ENV.test? 'sqrt'
end