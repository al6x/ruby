class Hash
  def inspect
    pairs = []
    each{|k, v| pairs << "#{k}: #{v.inspect}" }
    "{ " + pairs.join(', ') + " }"
  end

  def delete! *args; delete *args end
end