module Orel
  # An Orel::Table lets you perform basic sql operations on a heading.
  class Table

    def initialize(relation_namer, heading)
      @heading = heading
      @table = Orel::SqlGenerator::Table.new(relation_namer, heading)
    end

    # Public: Get all rows in the table. The results are ordered by the primary key.
    #
    # Returns an Array where each element is a Hash representing the row.
    def row_list
      attrs = @heading.attributes
      attr_names = attrs.map { |a| a.name }
      key = @heading.get_key(:primary)
      key_names = key.attributes.map { |a| a.name }
      result = execute("SELECT #{attr_names.join(',')} FROM #{@heading.name} ORDER BY #{key_names.join(',')}")
      result.each(:as => :hash, :symbolize_keys => true)
    end

    # Public: Get the number of rows in the table.
    #
    # Returns an Integer.
    def row_count
      rows = Orel.execute("SELECT COUNT(*) FROM #{@heading.name}")
      rows ? rows.first[0] : 0
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
    #
    # Returns an Array where each element is a Hash representing the row.
    def query
      table = Arel::Table.new(@heading.name)
      manager = Arel::SelectManager.new(table.engine)
      manager.from table
      yield manager, table
      execute(manager.to_sql).each(:as => :hash, :symbolize_keys => true)
    end

    # Public: Insert data into the table.
    #
    # attributes - Hash of key/values to insert.
    #
    # Returns nothing.
    def insert(options)
      execute(@table.insert_statement(options))
    end

    # Public: Insert data into the table but update one or more values
    # if there is a primary key conflict.
    #
    # options - Hash with keys:
    #         - :insert - Hash of attributes to insert.
    #         - :update - Hash with keys :values and :with describing
    #                     how to perform an update.
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
      insert = options.fetch(:insert)
      update = options.fetch(:update)
      execute(@table.upsert_statement(insert, update))
    end

    # Public: Update data in the table.
    #
    # options - Hash with keys:
    #         - :find - Hash of attributes to find.
    #         - :set  - Hash of attributes to change on the found rows.
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
      find = options.fetch(:find)
      set  = options.fetch(:set)
      execute(@table.update_statement(set, find))
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
    def delete(options)
      execute(@table.delete_statement(options))
    end

  protected

    def execute(statement)
      begin
        Orel.execute(statement)
      rescue StandardError => e
        debug_sql_error(statement)
        raise
      end
    end

  end
end
