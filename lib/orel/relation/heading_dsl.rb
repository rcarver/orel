module Orel
  module Relation
    class HeadingDSL

      def initialize(klass, database, child_name=nil, &block)
        @klass = klass
        @database = database
        @child_name = child_name
        @block = block

        name = database.relation_name(child_name)
        @heading = Heading.new(name)

        @keys = []
      end

      def key(name=:primary, &block)
        @keys << KeyDSL.new(name, @heading, &block)
      end

      def att(name, domain)
        @heading.attributes << Attribute.new(name, domain.new)
      end

      def ref(klass, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        child_name = args.first
        # TODO: validate options
        # TODO: allow references to non-primary keys
        reference = Reference.new(klass, nil, @klass, @child_name, :primary)
        reference.one_to_one = options[:unique]
        @heading.references << reference
      end

      def _apply!
        # Execute instructions.
        instance_eval(&@block)

        # Keys must be created after attributes.
        @keys.each { |dsl| dsl._apply! }

        # Add the heading to the database.
        @database.headings << @heading
      end

    end
  end
end
