module Orel
  module Relation
    class Namer

      def self.for_class(klass)
        Namer.new(klass.name.underscore.gsub(/\//, '_'), true)
      end

      def initialize(name, pluralize)
        @name = name
        @pluralize = pluralize
      end

      def for_child(name)
        Namer.new([@name, name].join("_"), false)
      end

      def heading_name
        if @pluralize
          @name.pluralize.to_sym
        else
          @name.to_sym
        end
      end

      # Used in Attribute.
      def foreign_key_name(attribute_name)
        if attribute_name == :id
          fk_name = [@name, attribute_name].join('_').to_sym
        else
          attribute_name
        end
      end

      # Used to generate sql
      def unique_key_name(attribute_names)
        [@name, attribute_names].flatten.join('_').to_sym
      end

      # Used to generate sql
      def foreign_key_constraint_name(this_name, other_name)
        [this_name, other_name, 'fk'].join('_').to_sym
      end

    end
  end
end
