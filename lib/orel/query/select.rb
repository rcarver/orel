module Orel
  class Query
    class Select
      attr_reader :projected_joins
      attr_reader :locked_for_query
      attr_reader :batch_size
      attr_reader :batch_group
      attr_reader :batch_order

      def initialize(select_manager, heading)
        @select_manager = select_manager
        @heading = heading
        @joins = {}
        @projected_joins = []
        @locked_for_query = true
      end

      # Public: Specify a condition on the query.
      #
      # condition - An object that can be joined, such as:
      #             Arel::Nodes::Node, as returned by arel_table[:attribute].
      #             Orel::Query::Join as returned by orel_table[Class]
      #
      # Returns nothing.
      def where(condition)
        case condition
        when Join
          add_join(condition)
          condition.wheres.each { |where| @select_manager.where(where) }
        when Arel::Nodes::Node
          @select_manager.where(condition)
        else
          raise "Unhandled where condition of type #{condition.inspect}"
        end
        nil
      end

      # Public: Specify an association to be included in the result set.
      # Calling this prepopulates the association on the returned
      # objects.
      #
      # join - Orel::Query::Join as returned by
      #        orel_table[Class or :simple_association].
      #
      # Returns nothing.
      def project(join)
        unless join.is_a?(Orel::Query::Join)
          raise ArgumentError, "Projection must be a join (was a #{join.class})"
        end
        add_join(join)
        @projected_joins << join
        join.project_attributes.each { |a|
          @select_manager.project(a)
        }
        nil
      end

      # Public: By default, objects returned by a query are locked from
      # making further queries. This ensures that by default, you're not
      # doing n+1 queries unintentionally. It's perfectly reasonable to
      # wish to allow objects to query their associations, in which case
      # specify `unlock_for_query!`.
      #
      # Returns nothing.
      def unlock_for_query!
        @locked_for_query = false
        nil
      end

      # Public: Specify that you want the results to be queried in batches.
      #
      # options - Hash of options.
      #           :size  - Number of rows to query in each batch (default: 1000).
      #           :group - Boolean whether to enumerate results individually or by batch.
      #           :order - Boolean whether to order the query by the key, or leave to natural order.
      #
      # Returns nothing.
      def query_batches(options)
        @batch_size = options.delete(:size) || 1000
        @batch_group = options.delete(:group) || false
        @batch_order = options.key?(:order) ? options.delete(:order) : true
        raise ArgumentError, "Unknown options: #{options.keys.inspect}" if options.any?
      end

      protected

      def add_join(join)
        unless @joins[join.join_id]
          @select_manager.join(join.join_table).on(*join.join_conditions)
          @joins[join.join_id] = true
        end
      end
    end
  end
end
