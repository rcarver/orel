module Orel
  module Relation
    class Key

      def initialize(name)
        @name = name
        @attributes = []
      end

      attr_reader :name
      attr_reader :attributes

      # Public: Convert this key into its foreign key equivalent.
      #
      # relation_name - String name of the
      #
      # Returns a new Orel::Relation::Key.
      def foreign_key_for(heading)
        fk_name = [heading.name, name].join("_").to_sym
        foreign_key = self.class.new(fk_name)
        attributes.each { |attribute|
          begin
            foreign_key.attributes << attribute.foreign_key_for(heading)
          rescue ForeignKeyTranslationError => e
            raise "Cannot convert key #{name} to a foreign key. #{e.message}"
          end
        }
        foreign_key
      end

    end
  end
end
