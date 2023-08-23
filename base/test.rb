require_relative 'env'
require_relative 'terminal'

def assert expr
  return if expr
  raise "Assertion failed" # raise "Assertion failed #{@actual.inspect} == #{expected.inspect}"
end

def test name
  return unless ENV.test? name.to_s
  puts Terminal.grey("  test |         #{caller[0].split(':').first.split('/').last} #{name}")
  yield
end

if __FILE__ == $0
  test "1 == 1" do
    assert 1 == 1
  end
end