module Orel
  module Relation
    class HeadingDSL

      def initialize(klass, set, namer, child_name=nil, &block)
        @klass = klass
        @set = set
        @namer = namer
        @child_name = child_name
        @block = block

        name = child_name ? namer.child_name(child_name) : namer.base_name
        @heading = Heading.new(name)

        @keys = []
      end

      def key(name=:primary, &block)
        @keys << KeyDSL.new(name, @heading, &block)
      end

      def att(name, domain)
        @heading.attributes << Attribute.new(@heading, @namer, name, domain.new)
      end

      def ref(klass, child_name=nil)
        # TODO: allow references to non-primary keys
        reference = Reference.new(klass, nil, @klass, @child_name, :primary)
        @heading.references << reference
      end

      def _apply!
        # Execute instructions.
        instance_eval(&@block)

        # Keys must be created after attributes.
        @keys.each { |dsl| dsl._apply! }

        # Add the heading to the set.
        @set << @heading
      end

    end
  end
end
