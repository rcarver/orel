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

      attr_writer :on_delete
      attr_writer :on_update

      def create_foreign_key_relationship!
        # Default on_delete to restrict.
        unless @on_delete
          @on_delete = Orel::Relation::Cascade::RESTRICT
        end

        # Default on_update based on the parent key.
        unless @on_update
          # Determine if the referenced key is a surrogate key and change the cascade behavior.
          parent_key_is_serial = parent_key.attributes.size == 1 && parent_key.attributes.first.domain.is_a?(Orel::Domains::Serial)
          if parent_key_is_serial
            @on_update = Orel::Relation::Cascade::RESTRICT
          else
            @on_update = Orel::Relation::Cascade::CASCADE
          end
        end

        # Add attributes in the parent heading to the child heading.
        child_heading.attributes.concat parent_key.attributes.map { |a|
          a.to_foreign_key
        }

        # Create a key that references the parent heading.
        child_key = parent_key.foreign_key_for(parent_heading)

        # Store a foreign key description on the child heading.
        cascade = Orel::Relation::Cascade.new(@on_delete, @on_update)
        child_heading.foreign_keys << ForeignKey.new(parent_heading, parent_key, child_heading, child_key, cascade)
      end

      def parent_heading
        @parent_class.get_heading(@parent_heading_name)
      end

      def child_heading
        @child_class.get_heading(@child_heading_name)
      end

      def parent_key
        key = parent_heading.get_key(@parent_key_name)
        key or raise "#{parent_heading.name} has no key #{@parent_key_name.inspect}"
      end

      def child_key
        key = child_heading.get_key(@child_key_name)
        key or raise "#{child_heading.name} has no key #{@child_key_name.inspect}"
      end

    end
  end
end
