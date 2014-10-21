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
  # Queries can be returned in one or many result sets. By specifying "batch"
  # options, the number of results is limited. This is useful for iterating
  # over very large sets of data. The  result of a batch query is an Enumerator
  # object.
  #
  # Specify `size` to the max number of records to return.
  #
  #     users = User.query { |q, user|
  #       q.query_batches :size => 1000
  #     }
  #     users.each do |user|
  #     end
  #
  # Specify `group => true` to give each batch as an Array, rather than each
  # object one at a time.
  #
  #     users = User.query { |q, user|
  #       q.query_batches :size => 1000, :group => true
  #     }
  #     users.each do |batch|
  #       batch.size # => 1000
  #       batch.each do |user|
  #       end
  #     end
  #
  # Specify `order => false` in order to *not* use the primary key as the
  # order.  This may be useful if you want to do consistent nonblocking read.
  # http://dev.mysql.com/doc/refman/5.0/en/innodb-consistent-read.html
  #
  #     users = User.query { |q, user|
  #       q.query_batches :size => 1000, :order => false
  #     }
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

    def initialize(klass)
      @klass = klass
      @heading = @klass.get_heading
      @connection = @klass.connection
    end

    # Internal: Perform a query.
    #
    # description - String description of the query for logging (default: none).
    #
    # Yields Orel::Query::Select, Orel::Query::Relation
    #
    # Returns an Array of Orel::Object. If batching is enabled, returns an
    #   Enumerator which yields objects or batches of objects.
    def query(description=nil)
      # Setup Arel query engine.
      table = @connection.arel_table(@heading)
      manager = Arel::SelectManager.new(table.engine)
      manager.from table

      # Overlay Orel heading and association information.
      query = Select.new(manager, @heading)
      relation = Relation.new(table, @klass, @heading, @connection)

      # Always project the full heading so that we can instantiate
      # fully valid objects.
      @heading.attributes.each { |a| manager.project table[a.name] }

      # Yield to customize the query.
      yield query, relation if block_given?

      # Initialize a Batch which can either read everything at once, or break
      # it into chunks.
      batch = Batch.new(@klass, @heading, @connection, query, manager, description)

      BatchQuery.new(query, batch, @heading, manager, table).results
    end

  protected

    class Relation
      def initialize(table, klass, heading, connection)
        @table = table
        @klass = klass
        @heading = heading
        @connection = connection
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
          table = key.connection.arel_table(heading)
          @joins[heading.name] ||= Join.new(make_join_id, @klass, @heading, @table, klass, heading, table)
        else
          if @simple_associations.include?(key)
            heading = @klass.get_heading(key)
            table = @connection.arel_table(heading)
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
