module Orel
  # Orel queries are modeled after the Arel query language. Think of it as a
  # subset of the full Arel language with a bit of extra convenience.
  #
  # A query's syntax is of the form:
  #
  #     Class.query { |select, relation|
  #       # ...
  #     }
  #
  # The `select` argument is generally named to `q` for query.
  # The `relation` argument is generally named after the class being queried.
  #
  #     User.query { |q, user|
  #       # ...
  #     }
  #
  # Following is a description of how to use the select and relation objects
  # to construct a query.
  #
  #
  # Relation
  #
  # Instructions for the query are built up backwards, starting with
  # the relation. The relation only responds to the `[]` method, which
  # may be called with various types of arguments.
  #
  #   * Symbol name of an attribute on the relation.
  #     Returns an Arel::Node on which any Arel comparison may be used,
  #     such as `eq`, `gt`, etc.
  #
  #   * Symbol name of a simple association on the relation.
  #     Returns a "join" object which responds to the `eq` operator.
  #
  #   * Class of a class association.
  #     Returns a "join" object which responds to the `eq` operator.
  #
  # Relation examples
  #
  #     # The name.
  #     relation[:name].eq('John')
  #
  #     # The name of the associated user.
  #     relation[User][:name].eq('John')
  #
  #     # The age of the associated user.
  #     relation[User][:age].gt(30)
  #
  #     # The ip address from the `logins` association.
  #     relation[:logins][:ip].eq('127.0.0.1')
  #
  #     # The associated user. Equality is determined by the primary key.
  #     relation[User].eq(@user)
  #
  #     # The user association.
  #     relation[User]
  #
  #     # The logins association
  #     relation[:logins]
  #
  #
  # Select
  #
  # Relation operations that return Arel::Node-like objects may be passed
  # to the `where` method. This adds restrictions to the query.
  #
  # Relation operations that return an association may be passed to the
  # `project` method. This results in those associations being pre-loaded
  # into the resulting objects.
  #
  # Select examples
  #
  #   # Restrict results to users whose name is John
  #   select.where relation[:name].eq('John')
  #
  #   # Restrict results to users that have logged in from 127.0.0.1
  #   select.where relation[:logins][:ip].eq('127.0.0.1')
  #
  #   # Return users with all of their logins
  #   select.project relation[:logins]
  #
  #
  # Preload & Lock for Query
  #
  # By default, objects returned from queries have the `lock_for_query` bit
  # set to true. This prevents them from performing queries that fetch
  # their associations. The intent here is that you should understand
  # the full set of data required when performing complex queries and design
  # those queries appropriately. When objects automatically fetch their
  # associations, it's very easy to introduce N+1 query issues.
  #
  # To override this behavior and allow resulting objects to query their
  # associations, call `unlock_for_query!` on the select.
  #
  # Examples
  #
  #     # Allow resulting objects to fetch their associations.
  #     select.unlock_for_query!
  #
  # Note that preloading is not always a good idea. In the above example of
  # returning a user and its logins, the resulting relation contains a full
  # copy of the user heading for each login. Returning this larger amount
  # of data over the network may sometimes conflict with the reduced number
  # of overall queries.
  #
  #     | name | ip          |
  #     |------|-------------|
  #     | John | 127.0.0.1   |
  #     | John | 192.168.0.1 |
  #     | ...etc...          |
  #
  class Query
    include Orel::SqlDebugging

    def initialize(klass, heading, connection)
      @klass = klass
      @heading = heading
      @connection = connection
    end

    # Internal: Perform a query.
    #
    # description - String description of the query for logging (default: none).
    #
    # Yields Orel::Query::Select, Orel::Query::Relation
    #
    # Returns an Array of Orel::Object.
    def query(description=nil)
      # Setup Arel query engine.
      table = Orel.arel_table(@heading)
      manager = Arel::SelectManager.new(table.engine)
      manager.from table

      # Overlay Orel heading and association information.
      query = Select.new(manager, @heading)
      relation = Relation.new(table, @klass, @heading)

      # Always project the full heading so that we can instantiate
      # fully valid objects.
      @heading.attributes.each { |a| manager.project table[a.name] }

      # Yield to customize the query.
      yield query, relation if block_given?

      # Execute the query.
      rows = execute(manager.to_sql, description || "#{self.class} on #{@klass}")

      # Extract objects from rows.
      if query.projected_joins.empty?
        objects = extract_objects_without_joins(rows)
      else
        objects = extract_objects_with_joins(query.projected_joins, rows)
      end

      # Finalize and return the objects.
      objects.each { |object|
        # The object is persisited because it came from the databse.
        object.persisted!

        # The object is readonly because it's a complex relation
        object.readonly!

        # The object is locked for query because you should get all
        # of the data you're interested in one shot.
        object.locked_for_query! if query.locked_for_query
      }
    end

  protected

    def extract_objects_without_joins(rows)
      rows.each(:as => :hash).map { |row|
        @klass.new(row)
      }
    end

    def extract_objects_with_joins(projected_joins, rows)
      objects = []
      objects_hash = {}
      rows.each(:as => :hash) { |row|

        # Extract association projections from the row.
        association_projections = {}
        projected_joins.each { |join|
          join_id = join.join_id
          association_projections[join.join_class] = {}
          row.each { |key, value|
            if key[0, join_id.size] == join_id
              name = key[(join_id.size)..-1]
              row.delete(key)
              association_projections[join.join_class][name] = value
            end
          }
        }

        # Only instantiate the object once.
        if objects_hash[row]
          object = objects_hash[row]
        else
          object = objects_hash[row] = @klass.new(row)
          objects << object
        end

        projected_joins.each { |join|
          object._store_association(join.join_class, association_projections[join.join_class])
        }
      }
      objects
    end

    def execute(statement, description=nil)
      begin
        @connection.execute(statement, description)
      rescue StandardError => e
        debug_sql_error(statement)
        raise
      end
    end

    class Select
      def initialize(select_manager, heading)
        @select_manager = select_manager
        @heading = heading
        @joins = {}
        @projected_joins = []
        @locked_for_query = true
      end

      attr_reader :projected_joins
      attr_reader :locked_for_query

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

    protected

      def add_join(join)
        unless @joins[join.join_id]
          @select_manager.join(join.join_table).on(*join.join_conditions)
          @joins[join.join_id] = true
        end
      end
    end

    class Relation
      def initialize(table, klass, heading)
        @table = table
        @klass = klass
        @heading = heading
        @simple_associations = SimpleAssociations.new(klass, klass.relation_set, klass.connection)
        @join_id = 0
        @joins = {}
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
          klass = key
          heading = key.get_heading
          table = Orel.arel_table(heading)
          @joins[heading.name] ||= Join.new(make_join_id, @klass, @heading, @table, klass, heading, table)
        else
          if @simple_associations.include?(key)
            heading = @klass.get_heading(key)
            table = Orel.arel_table(heading)
            @joins[heading.name] ||= Join.new(make_join_id, @klass, @heading, @table, key, heading, table)
          else
            @table[key]
          end
        end
      end

    protected

      def make_join_id
        "j#{@join_id += 1}__"
      end
    end

    class Join
      def initialize(join_id, klass, heading, table, join_class, join_heading, join_table)
        @join_id = join_id
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
      attr_reader :join_class
      attr_reader :join_id

      def project_attributes
        @join_heading.attributes.map { |a|
          column_alias = "#{join_id}#{a.name}"
          @join_table[a.name].as(Arel::SqlLiteral.new(column_alias))
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
