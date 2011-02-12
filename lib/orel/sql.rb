module Orel
  module Sql

    module Quoting
      def q(str)
        "`#{str}`"
      end
    end

    class Database
      include Quoting
      def initialize(tables)
        @tables = tables
      end
      def drop_tables!
        @tables.each { |table|
          Orel.execute "DROP TABLE IF EXISTS #{q table.name}"
        }
      end
      def create_tables!
        @tables.each { |table|
          table.statements.each { |statement|
            Orel.execute(statement)
          }
        }
      end
      def show_create_tables
        sorted = @tables.sort_by { |t| t.name }
        sorted.map { |table|
          result = Orel.query("SHOW CREATE TABLE #{q table.name}")
          result[0][1]
        }
      end
    end

    class Table
      include Quoting
      def initialize(name, heading)
        @name = name
        @heading = heading
      end
      attr_reader :name
      def statements
        sql = []
        sql << "CREATE TABLE #{q @name}"
        sql << "("
        inside  = []
        @heading.attributes.each { |attribute|
          column = Column.new(attribute.name, attribute.domain)
          inside << column.create_statement(self)
        }
        @heading.keys.each { |key|
          key_name = [@name, key.attributes.map { |a| a.name }].flatten.join("_")
          unique_key = UniqueKey.new(key_name, key.attributes)
          inside << unique_key.create_statement(self)
        }
        sql << inside.join(", ")
        sql << ")"
        # TODO: allow setting these options somewhere
        sql << "ENGINE=InnoDB DEFAULT CHARSET=utf8"
        sql.join(" ")
      end
    end

    class Column
      include Quoting
      def initialize(name, domain)
        @name = name
        @domain = domain
      end
      def create_statement(table)
        type_def = @domain.type_def
        "#{q @name} #{type_def}"
      end
    end

    class UniqueKey
      include Quoting
      def initialize(name, attributes)
        @name = name
        @attributes = attributes
      end
      def create_statement(table)
        attribute_names = @attributes.map { |a| q a.name }
        "UNIQUE KEY #{q @name} (#{attribute_names.join(',')})"
      end
    end

  end
end
