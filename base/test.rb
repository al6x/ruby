require_relative 'env'

def test name
  return unless ENV.test? name.to_s
  puts "  test |         #{caller[0].split(':')[0]} #{name}"
  yield
end