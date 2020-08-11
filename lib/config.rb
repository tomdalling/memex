class Config
  value_semantics do
    todoist_api_token Either(String, nil), default: nil
    memex_image_path Pathname, coerce: Pathname.method(:new)
    memex_volume_name String, default: 'Memex'
  end

  def self.[](attr)
    instance.public_send(attr)
  end

  def self.instance
    @instance ||= begin
      yml = Memex::CONFIG_PATH.read
      attrs = YAML.safe_load(yml, symbolize_names: true)
      new(attrs)
    end
  end

  def memex_volume_path
    Pathname('/Volumes') / memex_volume_name
  end
end
