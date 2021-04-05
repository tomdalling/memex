module Reference
  # TODO: extract these into a repo object
  def self.each(&block)
    if block
      # TODO: This should be moved to a proper repository layer.
      Config.instance.reference_dir.glob('*' + Nodoor::Repo::SIDECAR_METADATA_EXT) do |metadata_path|
        doc_id = File.basename(metadata_path.delete_suffix(Nodoor::Repo::SIDECAR_METADATA_EXT), '.*')
        block.(Doc.new(doc_id))
      end
    else
      to_enum
    end
  end

  def self.unused_document_base_path(date, file_system: FileSystem, config: Config.instance)
    (1..).each do |suffix|
      doc_id = "#{date.iso8601}_#{suffix.to_s.rjust(3, '0')}"
      unless document_id_exists?(doc_id, file_system: file_system, config: config)
        return config.reference_dir.join(doc_id)
      end
    end
  end

  def self.document_id_exists?(doc_id, file_system: FileSystem, config: Config.instance)
    file_system.children_of(config.reference_dir).any? do
      _1.basename.to_s.start_with?(doc_id)
    end
  end
end
