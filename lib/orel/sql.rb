module Orel
  module Sql

    def self.create_tables!(classes)
      Orel::SqlGenerator.creation_statements(classes).each { |s| Orel.execute(s) }
    end

    def insert(attributes)
      table = Orel::Sql::Table.new(get_heading)
      Orel.execute(table.insert_statement(attributes))
    end

    def update(options)
      key = options.fetch(:key)
      attributes = options.fetch(:update)
      table = Orel::Sql::Table.new(get_heading)
      Orel.execute(table.update_statement(key, attributes))
    end

    def delete(key_attributes)
      table = Orel::Sql::Table.new(get_heading)
      Orel.execute(table.delete_statement(key_attributes))
    end

    def on_duplicate_key_update
      key = options.fetch(:key)
      attributes = options.fetch(:values)
    end

  end
end
