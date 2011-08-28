module Orel
  module Relation
    # A key describes zero or more attributes that must be unique within a
    # relation.
    class Key

      # Internal: Initialize a new key.
      #
      # name - Symbol name of the key.
      #
      def initialize(name)
        @name = name
        @attributes = []
      end

      # Public: Get the name of the key.
      #
      # Returns a Symbol.
      attr_reader :name

      # Public: Get the attributes in the key.
      #
      # Returns an Array of Orel::Relation::Attribute.
      attr_reader :attributes

      # Public: Convert this key into its foreign key equivalent.
      #
      # heading - Heading that the key will be used in.
      #
      # Returns a new Orel::Relation::Key.
      def foreign_key_for(heading)
        fk_name = [heading.name, name].join("_").to_sym
        foreign_key = self.class.new(fk_name)
        attributes.each { |attribute|
          begin
            foreign_key.attributes << attribute.to_foreign_key
          rescue ForeignKeyTranslationError => e
            raise "Cannot convert key #{name} to a foreign key. #{e.message}"
          end
        }
        foreign_key
      end

    end
  end
end
