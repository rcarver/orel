module Orel
  module Relation
    class HeadingDSL

      def initialize(klass, block)
        @klass = klass
        @block = block
        @attributes = []
        @references = []
        @keys = {}
      end

      def key(name=:primary, &block)
        @keys[name] = KeyDSL.new(block)
      end

      def att(name, domain)
        attribute = Attribute.new(name, domain.new)
        @attributes << attribute
        attribute
      end

      def ref(klass, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        child_name = args.first
        # TODO: validate options
        # TODO: allow references to non-primary keys
        reference = Reference.new(klass, nil, @klass, child_name, :primary)
        reference.one_to_one = options[:unique]
        @references << reference
      end

      def _apply(database, child_name=nil)
        # Execute instructions.
        instance_eval(&@block)

        # Build the heading.
        name = database.relation_name(child_name)
        heading = Heading.new(name)

        # Apply results to the heading and database.
        @attributes.each { |a| heading.attributes << a }
        @references.each { |ref| heading.references << ref }
        @keys.each { |name, dsl| dsl._apply(name, heading) }

        # Add the heading to the database.
        database.headings << heading
      end

    end
  end
end
