module Orel
  module Relation
    # An attribute in a relation.
    class Attribute

      ForeignKeyTranslationError = Class.new(StandardError)

      # Internal: Initialize a new Attribute.
      #
      # heading - Relation::Heading that the attribute belongs to.
      # namer   - Relation::Namer.
      # domain  - Orel::Domain describing the type.
      #
      def initialize(heading, namer, name, domain)
        @heading = heading
        @namer = namer
        @name = name
        @domain = domain
      end

      # Public: Get the name of the attribute.
      #
      # Returns a String.
      attr_reader :name

      # Public: Get the domain of the attribute.
      #
      # Returns an Orel::Domain.
      attr_reader :domain

      # Internal: Transform this attribute into its foreign
      # equivalent.
      #
      # Returns a new Attribute where the name and domain may
      #   have been altered to act on the other end of the
      #   relationship.
      def to_foreign_key
        unless @heading
          raise ForeignKeyTranslationError, "Cannot convert to a foreign key because it already is one"
        end
        unless domain.respond_to?(:for_foreign_key)
          raise ForeignKeyTranslationError, "#{domain.inspect} does not support foreign keys. It must define `for_foreign_key`."
        end
        fk_name = @namer.foreign_key_name(name)
        fk_domain = domain.for_foreign_key
        self.class.new(nil, nil, fk_name, fk_domain)
      end

      # Public: Inspect the attribute.
      #
      # Returns a String.
      def inspect
        "<Attribute #{name.inspect} #{domain.class}>"
      end

    end
  end
end
