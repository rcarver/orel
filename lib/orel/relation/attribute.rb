module Orel
  module Relation
    class Attribute

      ForeignKeyTranslationError = Class.new(StandardError)

      # Internal: Initialize a new Attribute.
      #
      # heading - Heading the attribute belongs to.
      # name    - Symbol name of the heading.
      # domain  - Orel::Domain describing the type.
      #
      def initialize(heading, name, domain)
        @heading = heading
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
        # TODO: expose this naming assumption in a better way. It
        # should probably be an option to this method and be controller
        # by the DSL.
        if name == :id
          fk_name = [@heading.name, name].join("_").to_sym
        else
          fk_name = name
        end
        fk_domain = domain.for_foreign_key
        self.class.new(nil, fk_name, fk_domain)
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
