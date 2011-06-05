module Orel
  module Relation
    class Namer

      def initialize(klass)
        @klass = klass
        @name = @klass.name.underscore.gsub(/\//, '_')
      end

      def base_name
        @name.pluralize
      end

      def child_name(name)
        [@name, name].join('_')
      end

      def foreign_key_name(attribute_name)
        if attribute_name == :id
          fk_name = [@name, attribute_name].join('_')
        else
          attribute_name
        end
      end

      def unique_key_name(attribute_names)
        [@name, attribute_names].flatten.join('_')
      end

      def foreign_key_constraint_name(this_name, other_name)
        [this_name, other_name, 'fk'].join('_')
      end

    end
  end
end
