module Reference
  class Template
    include Metadata.value_semantics
      .without(:original_filename)
      .with { name String }
      .build_module

    def apply_to(metadata)
      metadata.with(to_h.compact.except(:name))
    end
  end
end
