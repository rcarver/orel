module Orel
  module Sql

    module Quoting
      def q(str)
        "`#{str}`"
      end
    end

    class Database
      include Quoting
      def initialize(tables, foreign_keys)
        @tables = tables
        @foreign_keys = foreign_keys
      end
      def create_tables!
        @tables.each { |table|
          puts table.statement.inspect
          Orel.execute(table.statement)
        }
        @foreign_keys.each { |foreign_key|
          puts foreign_key.statement.inspect
          Orel.execute(foreign_key.statement)
        }
      end
      #def show_create_tables
        #sorted = @tables.sort_by { |t| t.name }
        #sorted.map { |table|
          #Orel.query("SHOW CREATE TABLE #{q table.name}")[0][1]
        #}
      #end
    end

    class Table
      include Quoting
      def initialize(heading)
        @heading = heading
      end
      def name
        @heading.name
      end
      def columns
        @heading.attributes.map { |attribute|
          Column.new(attribute.name, attribute.domain)
        }
      end
      def unique_keys
        @heading.keys.map { |key|
          key_name = [name, key.attributes.map { |a| a.name }].flatten.join("_")
          UniqueKey.new(key_name, key.attributes)
        }
      end
      def statement
        sql = []
        sql << "CREATE TABLE #{q name}"
        sql << "("
        inside  = []
        columns.each { |column|
          inside << column.create_statement(self)
        }
        unique_keys.each { |unique_key|
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
      attr_reader :name
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

    class ForeignKey
      include Quoting
      def initialize(local_table_name, foreign_table_name, local_attributes, foreign_attributes)
        @local_table_name = local_table_name
        @foreign_table_name = foreign_table_name
        @local_attributes = local_attributes
        @foreign_attributes = foreign_attributes
      end
      def statement
        name = [@local_table_name, @foreign_table_name, "fk"].join("_")
        local_attribute_names = @local_attributes.map { |a| q a.name }
        foreign_attribute_names = @foreign_attributes.map { |a| q a.name }
        "ALTER TABLE #{q @local_table_name} ADD CONSTRAINT #{q name} FOREIGN KEY (#{local_attribute_names.join(',')}) REFERENCES #{q @foreign_table_name} (#{foreign_attribute_names.join(',')}) ON DELETE NO ACTION ON UPDATE NO ACTION"
      end
    end

  end
end
