module Orel
  module Relation
    class Attribute

      ForeignKeyTranslationError = Class.new(StandardError)

      def initialize(heading, name, domain)
        @heading = heading
        @name = name
        @domain = domain
      end

      attr_reader :name
      attr_reader :domain

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

      def inspect
        "<Attribute #{name.inspect} #{domain.class}>"
      end

    end
  end
end
