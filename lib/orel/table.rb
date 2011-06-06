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
      result = Orel.execute("SELECT #{attr_names.join(',')} FROM #{@heading.name} ORDER BY #{key_names.join(',')}").to_a
      result.map { |row|
        Hash[*attr_names.zip(row).flatten]
      }
    end

    # Public: Get the number of rows in the table.
    #
    # Returns an Integer.
    def row_count
      rows = Orel.execute("SELECT COUNT(*) FROM #{@heading.name}")
      rows ? rows.first[0] : 0
    end

    # Public: Insert data into the table.
    #
    # attributes - Hash of key/values to insert.
    #
    # Returns nothing.
    def insert(options)
      Orel.execute(@table.insert_statement(options))
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
      Orel.execute(@table.upsert_statement(insert, update))
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
      Orel.execute(@table.update_statement(set, find))
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
      Orel.execute(@table.delete_statement(options))
    end

  end
end
