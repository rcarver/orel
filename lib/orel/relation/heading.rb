module Orel
  module Relation
    # In most ways, this class describes a standard relational heading with
    # attributes, keys and foreign keys. On top of that it introduces
    # references which allow us to talk describe how classes are related by
    # the headings they define.
    class Heading

      def initialize(namer)
        @namer = namer
        @attributes = []
        @keys = []
        @references = []
        @foreign_keys = []
      end

      attr_accessor :namer

      # Public: Name of this heading.
      #
      # Returns a Symbol.
      def name
        @namer.heading_name
      end

      # TEMPORARY
      def with_namer(namer)
        heading = self.class.new(namer)
        heading.instance_variable_set(:@attributes, attributes)
        heading.instance_variable_set(:@keys, keys)
        heading.instance_variable_set(:@references, references)
        heading.instance_variable_set(:@foreign_keys, foreign_keys)
        heading
      end

      # Public: The relational attributes in this heading.
      # Attributes define the fields in a relation.
      #
      # Returns an Array of Orel::Relation::Attribute.
      attr_reader :attributes

      # Public: The relational keys in this heading. Keys
      # define the uniqueness of a heading.
      #
      # Returns an Array of Orel::Relation::Key.
      attr_reader :keys

      # Public: The foreign keys in this heading. Foreign keys
      # describe which of the keys in this heading relate to
      # keys in other headings.
      #
      # Returns an Array of Orel::Relation::ForeignKey.
      attr_reader :foreign_keys

      # Public: The references in this heading. References
      # describe how this heading references headings in
      # other classes.
      #
      # Returns an Array of Orel::Relation::Reference.
      attr_reader :references

      # Public: Get an attribute from the heading.
      #
      # name - Symbol name of the attribute.
      #
      # Returns an Orel::Relation::Attribute or nil.
      def get_attribute(name)
        attributes.find { |a| a.name == name }
      end

      # Public: Get a key in the heading.
      #
      # name - Symbol name of the key.
      #
      # Returns an Orel::Relation::Key or nil.
      def get_key(name)
        keys.find { |k| k.name == name }
      end

      # Public: Get the reference that points to a class as the child in
      # the relationship.
      #
      # klass - A Class that defines a heading.
      #
      # Returns an Orel::Relation::Reference or nil.
      def get_child_reference(klass)
        references.find { |r| r.child_class == klass }
      end

      # Public: Get the reference that points to a class as the parent in
      # the relationship.
      #
      # klass - A Class that defines a heading.
      #
      # Returns an Orel::Relation::Reference or nil.
      def get_parent_reference(klass)
        references.find { |r| r.parent_class == klass }
      end

    end
  end
end
