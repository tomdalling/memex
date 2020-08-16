module Todoist
  class Decorators::Everything < SimpleDelegator
    def items
      decorate(super)
    end

    def item(*content_or_attrs)
      find!(:items, content_or_attrs, default_attr: :content)
    end

    def projects
      decorate(super)
    end

    def project(*name_or_attrs)
      find!(:projects, name_or_attrs, default_attr: :name)
    end

    def labels
      decorate(super)
    end

    def label(*name_or_attrs)
      find!(:labels, name_or_attrs, default_attr: :name)
    end

    def decorate(model)
      return model if model.class.implements?(IDecorator)

      # TODO: could make this more open/closed
      case model
      when Array then model.map { decorate(_1) }
      when Item then Decorators::Item.new(model, self)
      when Project then Decorators::Project.new(model, self)
      when Label then model # no decorator yet
      else fail "Don't know how to decorate: #{model.inspect}"
      end
    end

    private

      def find!(collection_name, queries, default_attr:)
        raise ArgumentError if queries.empty?

        search_attrs = queries
          .map(&method(:normalize_query).curry.(default_attr))
          .reduce({}, &:merge)

        element = public_send(collection_name).find do |elem|
          search_attrs.all? { elem.public_send(_1) == _2 }
        end

        if element
          element
        else
          type = collection_name.to_s.capitalize.chomp('s')
          fail "#{type} not found for #{search_attrs.inspect}"
        end
      end

      def normalize_query(default_attr, query)
        if query.is_a?(Hash)
          query
        else
          { default_attr => query }
        end
      end
  end
end
