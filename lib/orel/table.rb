module Orel
  # An Orel::Table lets you perform basic sql operations on a heading.
  class Table

    def initialize(heading, connection)
      @heading = heading
      @connection = connection
    end

    # Public: Get all rows in the table. The results are ordered by the primary key.
    #
    # Examples
    #
    #     table.row_list
    #     # => [{ :name => "John", :points => 30 }, { :name => "Mary", :points => 50 }]
    #
    # Returns an Array where each element is a Hash representing the row.
    def row_list
      query("#{self.class} List rows in #{@heading.name}") { |q, table|
        @heading.attributes.each { |a|
          q.project table[a.name]
        }
        @heading.get_key(:primary).attributes.each { |a|
          q.order table[a.name].asc
        }
      }
    end

    # Public: Get the number of rows in the table.
    #
    # Examples
    #
    #     table.row_count
    #     # => 2
    #
    # Returns an Integer.
    def row_count
      rows = query("#{self.class} Count rows in #{@heading.name}") { |q, table|
        q.project Arel::Nodes::SqlLiteral.new('COUNT(*) count')
      }
      rows.first[:count]
    end

    # Public: Use Arel to query the table.
    #
    # yields the Arel::SelectManager and the Arel::Table.
    #
    # Examples
    #
    #     table.query { |q, table|
    #       q.project table[:name]
    #       q.where table[:points].gt(30)
    #     }
    #     # => [{ :name => "Mary", :points => 50 }]
    #
    # Returns an Array where each element is a Hash representing the row.
    def query(description=nil)
      table = @connection.arel_table(@heading)
      manager = Arel::SelectManager.new(table.engine)
      manager.from table
      select = Select.new(manager)
      yield select, table if block_given?

      batch = Batch.new(select, @heading, @connection)

      BatchQuery.new(select, batch, @heading, manager, table).results
    end

    class Batch
      def initialize(manager, heading, connection)
        @connection = connection
        @manager = manager
        @heading = heading
      end

      def read_all
        read
      end

      def read_batch(start, count)
        @manager.take count
        @manager.skip start
        read
      end

      def read
        @connection.execute(@manager.to_sql, @description || "#{self.class} Query #{@heading.name}").each(:as => :hash, :symbolize_keys => true)
      end
    end

    class Select
      attr_reader :batch_size
      attr_reader :batch_group
      attr_reader :batch_order

      def initialize(select_manager)
        @select_manager = select_manager
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

      def method_missing(message, *args, &block)
        @select_manager.send(message, *args, &block)
      end
    end

    # Public: Add another table to a query. You'll need to specify the
    # join condition within the query.
    #
    # alias - Symbol or String alias name for the table in sql.
    #
    # Yield an Arel::Table.
    #
    # Examples
    #
    #   table1.query { |q, t1|
    #     q.project t1[:name]
    #     table2.as { |t2|
    #       q.join(t2).on(t1[:id].eq(t2[:t1_id]))
    #       q.where t2[:age].gt(40)
    #     }
    #   }
    #
    # Returns nil if a block is given, else returns the Arel::Table.
    def as(aliaz=nil)
      table = @connection.arel_table(@heading)
      table = table.alias(aliaz.to_s) if aliaz
      if block_given?
        yield table
        nil
      else
        table
      end
    end

    # Public: Insert data into the table.
    #
    # attributes - Hash of key/values to insert.
    #
    # Examples
    #
    #     table.insert(:name => "John", :age => 30)
    #
    # Returns nothing.
    def insert(attributes)
      @connection.insert(insert_statement(attributes), "#{self.class} Insert into #{@heading.name}")
    end

    # Public: Insert data into the table but update one or more values
    # if there is a primary key conflict.
    #
    # options - Hash with keys:
    #           :insert - Hash of attributes to insert.
    #           :update - Hash describing how to perform the update.
    #                     :values - An array of Symbols describing the
    #                               attributes to update.
    #                     :with   - How you'd like to change the value
    #                               of each attribute. Options are
    #                               :increment or :replace.
    #
    # Examples
    #
    #     table.upsert(
    #       :insert => { :name => "John", :points => 1 },
    #       :update => { :values => [:points], :with => :increment }
    #     )
    #
    # Returns nothing.
    def upsert(options)
      @connection.execute(upsert_statement(options), "#{self.class} Upsert into #{@heading.name}")
    end

    # Public: Update data in the table.
    #
    # options - Hash with keys:
    #           :find - Hash of attributes to find.
    #           :set  - Hash of attributes to change on the found rows.
    #
    # Examples
    #
    #     table.update(
    #       :find => { :name => "John" },
    #       :set =>  { :poins => 30 }
    #     )
    #
    # Returns nothing.
    def update(options)
      @connection.execute(update_statement(options), "#{self.class} Update #{@heading.name}")
    end

    # Public: Delete data from the table.
    #
    # attributes - Hash of key/values used to find rows to delete.
    #
    # Examples
    #
    #     table.delete(:name => "John")
    #
    # Returns nothing.
    def delete(attributes)
      @connection.execute(delete_statement(attributes), "#{self.class} Delete from #{@heading.name}")
    end

    # Public: Delete all data from the table.
    #
    # Returns nothing.
    def truncate!
      # MySQL no longer allows truncate on tables with fk's.
      # See http://bugs.mysql.com/bug.php?id=54678
      @connection.execute "DELETE FROM `#{@heading.name}`"
    end

    def insert_statement(attributes)
      table = @connection.arel_table(@heading)
      manager = Arel::InsertManager.new(table.engine);
      manager.into table
      manager.insert ordered_hash(attributes).map { |k, v| [table[k], v] }
      manager.to_sql
    end

    def upsert_statement(options)
      insert = options.fetch(:insert) or raise ArgumentError, "Missing :insert attributes"
      update = options.fetch(:update) or raise ArgumentError, "Missing :update options"
      values = update[:values] or raise ArgumentError, "Missing :values to update"
      update_with = update[:with] or raise ArgumentError, "Missing :with describing how to update"
      values.all? { |v| insert.key?(v) } or raise ArgumentError, "All :values to update must have attributes to insert"
      update_statement = case update_with
      when :increment
        values.map { |v| "#{v}=#{v}+VALUES(#{v})" }.join(',')
      when :replace
        values.map { |v| "#{v}=VALUES(#{v})" }.join(',')
      else
        raise ArgumentError, "Unknown value for :with - #{with.inspect}"
      end
      "#{insert_statement(insert)} ON DUPLICATE KEY UPDATE #{update_statement}"
    end

    def update_statement(options)
      find = options[:find] or raise ArgumentError, "Missing :find attributes"
      set  = options[:set] or raise ArgumentError, "Missing :set attributes"
      table = @connection.arel_table(@heading)
      manager = Arel::UpdateManager.new(table.engine)
      manager.table table
      manager.set ordered_hash(set).map { |k, v| [table[k], v] }
      find.each { |k, v|
        manager.where table[k].eq(v)
      }
      manager.to_sql
    end

    def delete_statement(attributes)
      table = @connection.arel_table(@heading)
      manager = Arel::DeleteManager.new(table.engine)
      manager.from table
      ordered_hash(attributes).each { |k, v|
        manager.where table[k].eq(v)
      }
      manager.to_sql
    end

  protected

    def ordered_hash(hash)
      keys = hash.keys.map { |k| k.to_s }.sort
      keys.map { |k|
        sym = k.to_sym
        [sym, hash[sym]]
      }
    end

  end
end
