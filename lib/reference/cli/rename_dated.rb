module Reference
  class CLI::RenameDated < Dry::CLI::Command
    desc "Renames all reference files based on their `dated` metadata value"
    option :dry_run, type: :boolean, default: true, desc: "Don't actually rename, just output"

    def call(dry_run:)
      Config.instance.reference_dir.glob('*.metadata.yml').sort.each do
        rename(_1, dry_run: dry_run)
      end

      if dry_run
        puts "This was a dry run, so no files were moved. Use `--no-dry-run` to actually move files."
      end
    end

    private

      def rename(metadata_path, dry_run:)
        metadata = Metadata.from_yaml(metadata_path.read)
        return unless metadata.dated
        return if metadata_path.basename.to_s.start_with?(metadata.dated.iso8601)

        ref_id = metadata_path.basename.to_s.split('.').first
        base_path = Reference.unused_document_base_path(metadata.dated)
        Config.instance.reference_dir.glob("#{ref_id}.*") do |source_path|
          ext = '.' + source_path.basename.to_s.partition('.').last
          dest_path = base_path.sub_ext(ext)
          puts "Moving \"#{source_path}\" to \"#{dest_path}\""
          FileUtils.mv(source_path, dest_path) unless dry_run
        end
      end
  end
end
