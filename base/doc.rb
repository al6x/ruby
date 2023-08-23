module Docs
  Doc = Struct.new :title, :text, :tags
  Todo = Struct.new :text, :priority, :tags

  @docs = []
  self.attr_accessor :docs

  def doc title, text, *tags
    Docs.docs << Doc.new(title, text, tags)
  end

  def todo text, priority, *tags
    Docs.docs << Todo.new(text, priority, tags)
  end
end

if __FILE__ == $0
  include Docs
  a = []
  doc "Some title", "Some text", :a, :b
  todo "doit", :normal, :a, :b
  puts Docs.docs
end