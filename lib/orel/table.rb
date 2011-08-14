module Orel
  # An Orel::Table lets you perform basic sql operations on a heading.
  class Table
    include Orel::SqlDebugging

    def initialize(heading)
      @heading = heading
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
      table = Orel.arel_table(@heading)
      manager = Arel::SelectManager.new(table.engine)
      manager.from table
      yield manager, table
      execute(manager.to_sql, description || "#{self.class} Query #{@heading.name}").each(:as => :hash, :symbolize_keys => true)
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
      execute(insert_statement(attributes), "#{self.class} Insert into #{@heading.name}", :insert)
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
      execute(upsert_statement(options), "#{self.class} Upsert into #{@heading.name}")
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
      execute(update_statement(options), "#{self.class} Update #{@heading.name}")
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
      execute(delete_statement(attributes), "#{self.class} Delete from #{@heading.name}")
    end

    # Public: Delete all data from the table.
    #
    # Returns nothing.
    def truncate!
      execute "TRUNCATE TABLE `#{@heading.name}`"
    end

    def insert_statement(attributes)
      table = Orel.arel_table(@heading)
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
        values.map { |v| "#{v}=VALUES(#{v})" }
      else
        raise ArgumentError, "Unknown value for :with - #{with.inspect}"
      end
      "#{insert_statement(insert)} ON DUPLICATE KEY UPDATE #{update_statement}"
    end

    def update_statement(options)
      find = options[:find] or raise ArgumentError, "Missing :find attributes"
      set  = options[:set] or raise ArgumentError, "Missing :set attributes"
      table = Orel.arel_table(@heading)
      manager = Arel::UpdateManager.new(table.engine)
      manager.table table
      manager.set ordered_hash(set).map { |k, v| [table[k], v] }
      find.each { |k, v|
        manager.where table[k].eq(v)
      }
      manager.to_sql
    end

    def delete_statement(attributes)
      table = Orel.arel_table(@heading)
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

    def execute(statement, description=nil, op=:execute)
      begin
        case op
        when :execute: Orel.execute(statement, description)
        when :insert:  Orel.insert(statement, description)
        else raise ArgumentError, "Unknown execution operation #{op.inspect}"
        end
      rescue StandardError => e
        debug_sql_error(statement)
        raise
      end
    end

  end
end
