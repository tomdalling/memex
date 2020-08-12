require_relative 'item'
require_relative 'label'

module Todoist
  class Everything
    include JsonSemantics
    json_semantics do
      items Types::ArrayOf[Item]
      labels Types::ArrayOf[Label]
    end

    def label(attrs_or_name)
      find!(:labels, attrs_or_name, default_attr: :name)
    end

    private

      def find!(collection_name, query, default_attr:)
        search_attrs =
          if query.is_a?(Hash)
            query
          else
            { default_attr => query }
          end

        element = public_send(collection_name).find do |elem|
          search_attrs.all? { elem.public_send(_1) == _2 }
        end

        if element
          element
        else
          fail "#{collection_name.to_s.capitalize} not found for #{query.inspect}"
        end
      end
  end
end
