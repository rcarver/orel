module Orel
  module Relation
    class Heading

      def initialize(name)
        @name = name
        @attributes = []
        @keys = []
        @references = []
        @foreign_keys = []
      end

      attr_reader :name
      attr_reader :attributes
      attr_reader :keys
      attr_reader :references
      attr_reader :foreign_keys

      def get_attribute(name)
        attributes.find { |a| a.name == name }
      end

      def get_child_reference(klass)
        references.find { |r| r.child_class == klass }
      end

      def get_parent_reference(klass)
        references.find { |r| r.parent_class == klass }
      end

      def get_key(name)
        keys.find { |k| k.name == name }
      end

    end
  end
end
