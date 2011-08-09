module Orel
  module Relation
    class Reference

      def initialize(parent_class, parent_heading_name, parent_key_name, child_class, child_heading_name, child_key_name)
        @parent_class = parent_class
        @parent_heading_name = parent_heading_name
        @parent_key_name = parent_key_name
        @child_class = child_class
        @child_heading_name = child_heading_name
        @child_key_name = child_key_name
      end

      attr_reader :parent_class
      attr_reader :child_class

      def create_foreign_key_relationship!
        # Add attributes in the parent heading to the child heading.
        child_heading.attributes.concat parent_key.attributes.map { |a|
          a.to_foreign_key
        }

        # Create a key that references the parent heading.
        child_key = parent_key.foreign_key_for(parent_heading)

        # Store a foreign key description on the child heading.
        child_heading.foreign_keys << ForeignKey.new(parent_heading, parent_key, child_heading, child_key)
      end

      def parent_key
        parent_heading.get_key(@parent_key_name)
      end

      def child_key
        child_heading.get_key(@child_key_name)
      end

      def parent_heading
        @parent_class.get_heading(@parent_heading_name)
      end

      def child_heading
        @child_class.get_heading(@child_heading_name)
      end

    end
  end
end
