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
          query_proxy = QueryProxy.new(select_manager, @heading)
          table_proxy = TableProxy.new(table, @klass, @heading)
          yield query_proxy, table_proxy
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
        object.locked_for_query!
        object
      }
    end

    class QueryProxy
      def initialize(select_manager, heading)
        @select_manager = select_manager
        @heading = heading
        @joins = {}
      end
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
      end
      def join(join)
        return # no-op for now
        @joins[join.join_id] = join
        @select_manager.project(*join.attributes) if join.projected?
        @select_manager.join(join.join_table).on(*join.join_conditions)
      end
    end

    class TableProxy
      def initialize(table, klass, heading)
        @table = table
        @klass = klass
        @heading = heading
        @simple_associations = SimpleAssociations.new(klass, klass.relation_set)
      end
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
      def initialize(parent_klass, parent_heading, parent_table, join_class, join_heading, join_table)
        @parent_class = parent_klass
        @parent_heading = parent_heading
        @parent_table = parent_table
        @join_class = join_class
        @join_heading = join_heading
        @join_table = join_table
        @wheres = []

        @child_reference = @join_heading.get_parent_reference(@parent_class)
        @parent_reference = @parent_class.get_heading.get_parent_reference(@join_class)
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
          @parent_heading.get_key(:primary).attributes.map { |a|
            @parent_table[a.name].eq(@join_table[a.to_foreign_key.name])
          }
        when @parent_reference
          @join_heading.get_key(:primary).attributes.map { |a|
            @parent_table[a.to_foreign_key.name].eq(@join_table[a.name])
          }
        else
          raise "No child or parent reference was found for parent:#{@parent_class} join:#{@join_class}"
        end
      end

      # Public: Retrieve an attribute from the join table.
      #
      # name - Symbol name of the attribute.
      #
      # Returns a JoinProxy on which to specify conditions of the
      #   attribute.
      def [](name)
        JoinProxy.new(self, @join_table[name])
      end

      # Public: Limit the results to objects that contain an object in
      # a child association.
      #
      # object - Orel::Object found in a child relationship.
      #
      # Returns this Join object.
      def contains(object)
        unless object.is_a?(@join_class)
          raise ArgumentError, "Expected a #{@join_class} but got a #{object.class}"
        end
        unless @child_reference
          raise ArgumentError, "No child reference was found from parent:#{@parent_class.inspect} to join:#{@join_class.inspect}"
        end
        @child_reference.parent_key.attributes.each { |a|
          @wheres << @parent_table[a.name].eq(object[a.to_foreign_key.name])
        }
        self
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
        unless @parent_reference
          raise ArgumentError, "No parent reference was found from parent:#{@parent_class.inspect} to join:#{@join_class.inspect}"
        end
        @parent_reference.parent_key.attributes.each { |a|
          @wheres << @parent_table[a.name].eq(object[a.to_foreign_key.name])
        }
        self
      end
    end

    class JoinProxy
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