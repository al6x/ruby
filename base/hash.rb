class Hash
  def inspect
    pairs = []
    each{|k, v| pairs << "#{k}: #{v.inspect}" }
    "{ " + pairs.join(', ') + " }"
  end

  def delete! *args; delete *args end

  def symbolize_keys
    transform_keys{|key| key.to_sym }
  end
end