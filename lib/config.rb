class Config
  class TodoistConfig
    value_semantics do
      api_token String
      master_checklists_project String
      active_checklists_project String
      checklist_trigger_label String
    end
  end

  class MemexConfig
    value_semantics do
      image_path Pathname, coerce: Pathname.method(:new)
      volume_path Pathname, coerce: Pathname.method(:new)
    end
  end

  value_semantics do
    memex MemexConfig, coerce: MemexConfig.coercer
    todoist Either(TodoistConfig, nil), coerce: TodoistConfig.coercer
  end

  class << self
    extend Forwardable
    def_delegators :instance, *%i(memex todoist)

    def instance
      @instance ||= begin
        yml = Memex::CONFIG_PATH.read
        attrs = YAML.safe_load(yml, symbolize_names: true)
        new(attrs)
      end
    end
  end
end
