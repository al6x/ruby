class NilClass
  def empty?; true end
end

if __FILE__ == $0
  p nil.empty?
end