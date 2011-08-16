module Orel
  class Query

    def initialize(klass, heading)
      @klass = klass
      @heading = heading
    end

    def query(description=nil)
      results = @klass.table.query(description || "Orel::Query") { |select_manager, table|
        @heading.attributes.each { |a| select_manager.project table[a.name] }

        if block_given?
          query = Select.new(select_manager, @heading)
          relation = Relation.new(table, @klass, @heading)
          yield query, relation
        end
      }
      results.map { |row|
        object = @klass.new(row)
        # The object is persisited because it came from the databse.
        object.persisted!
        # The object is readonly because it's a complex relation
        object.readonly!
        # The object is locked for query because you should get all
        # of the data you're interested in one shot.
        #object.locked_for_query!
        object
      }
    end

    class Select
      def initialize(select_manager, heading)
        @select_manager = select_manager
        @heading = heading
        @joins = {}
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
          @select_manager.join(condition.join_table).on(*condition.join_conditions)
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
      def join(join)
        return # no-op for now
        @joins[join.join_id] = join
        @select_manager.project(*join.attributes) if join.projected?
        @select_manager.join(join.join_table).on(*join.join_conditions)
        nil
      end
    end

    class Relation
      def initialize(table, klass, heading)
        @table = table
        @klass = klass
        @heading = heading
        @simple_associations = SimpleAssociations.new(klass, klass.relation_set)
      end

      # Public: Get an attribute or association, with the intent of
      # adding it to the current query.
      #
      # key - Symbol attribute, Class or symbol of simple association.
      #
      # Examples
      #
      #   table_proxy[:name] # => Arel::Nodes::Node
      #   table_proxy[:simple_association] # => Orel::Query::Join
      #   table_proxy[OrelClassReference] # => Orel::Query::Join
      #
      # Returns an object suitable for passing to QueryProxy methods.
      def [](key)
        case key
        when Class
          heading = key.get_heading
          table = Orel.arel_table(heading)
          Join.new(@klass, @heading, @table, key, heading, table)
        else
          if @simple_associations.include?(key)
            heading = @klass.get_heading(key)
            table = Orel.arel_table(heading)
            Join.new(@klass, @heading, @table, nil, heading, table)
          else
            @table[key]
          end
        end
      end
    end

    class Join
      def initialize(klass, heading, table, join_class, join_heading, join_table)
        @class = klass
        @heading = heading
        @table = table
        @join_class = join_class
        @join_heading = join_heading
        @join_table = join_table
        @wheres = []

        @child_reference = @join_heading.get_parent_reference(@class)
        @parent_reference = @class.get_heading.get_parent_reference(@join_class)
      end

      attr_reader :wheres
      attr_reader :join_table

      def join_id
        @join_id ||= "j1"
      end

      def attributes
        @join_heading.attributes.map { |a|
          @join_table[a.name].as("#{join_id}__#{a.name}")
        }
      end

      def join_conditions
        case
        when @child_reference
          @heading.get_key(:primary).attributes.map { |a|
            @table[a.name].eq(@join_table[a.to_foreign_key.name])
          }
        when @parent_reference
          @join_heading.get_key(:primary).attributes.map { |a|
            @table[a.to_foreign_key.name].eq(@join_table[a.name])
          }
        else
          raise "No child or parent reference was found for class:#{@class} join:#{@join_class}"
        end
      end

      # Public: Retrieve an attribute from the join table.
      #
      # name - Symbol name of the attribute.
      #
      # Returns a JoinProxy on which to specify conditions of the attribute.
      def [](name)
        JoinCondition.new(self, @join_table[name])
      end

      # Public: Limit the results to objects that have an object as
      # their parent.
      #
      # object - Orel::Object in the parent relationshin the parent
      #          relationship.
      #
      # Returns this Join object.
      def eq(object)
        unless object.is_a?(@join_class)
          raise ArgumentError, "Expected a #{@join_class} but got a #{object.class}"
        end
        case
        when @parent_reference
          @parent_reference.parent_key.attributes.each { |a|
            @wheres << @table[a.name].eq(object[a.to_foreign_key.name])
          }
        when @child_reference
          @child_reference.parent_key.attributes.each { |a|
            @wheres << @table[a.name].eq(object[a.to_foreign_key.name])
          }
        else
          raise ArgumentError, "No reference was found from class:#{@class.inspect} to join:#{@join_class.inspect}"
        end
        self
      end
    end

    class JoinCondition
      def initialize(join, attribute)
        @join = join
        @attribute = attribute
      end

      # Public: Perform an Arel node operation such as `eq`.
      #
      # Returns the underlying Join.
      def method_missing(message, *args)
        @join.wheres << @attribute.__send__(message, *args)
        @join
      end
    end

  end
end
