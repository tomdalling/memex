module Reference
  # TODO: extract these into a repo object
  def self.each(&block)
    if block
      Config.instance.reference_dir.glob('*.metadata.yml') do |metadata_path|
        doc_id = metadata_path.basename.to_s.delete_suffix('.metadata.yml')
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
