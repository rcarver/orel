module Orel
  module Sql

    def self.create_tables!(classes)
      translator = RelationTranslator.new(*classes)
      database = translator.database
      database.create_tables!
    end

    class RelationTranslator
      def initialize(*classes)
        @classes = classes
      end
      def database
        tables = @classes.map { |klass|
          klass.database.headings.map { |heading|
            Orel::Sql::Table.new(heading)
          }
        }

        foreign_keys = @classes.map { |klass|
          klass.database.foreign_keys.map { |foreign_key|
            parent_table = Orel::Sql::Table.new(foreign_key.parent_heading)
            child_table = Orel::Sql::Table.new(foreign_key.child_heading)
            parent_attributes = foreign_key.parent_key.attributes
            child_attributes = foreign_key.child_key.attributes
            Orel::Sql::ForeignKey.new(parent_table.name, parent_attributes, child_table.name, child_attributes)
          }
        }

        Orel::Sql::Database.new(tables.flatten, foreign_keys.flatten)
      end
    end

    module Quoting
      def quote_column_name(name)
        Orel.connection.quote_column_name(name)
      end
      def quote_table_name(name)
        Orel.connection.quote_table_name(name)
      end
      alias_method :qc, :quote_column_name
      alias_method :qt, :quote_table_name
    end

    class Database
      include Quoting
      def initialize(tables, foreign_keys)
        @tables = tables
        @foreign_keys = foreign_keys
      end
      def create_tables!
        @tables.each { |table|
          Orel.execute(table.create_statement)
        }
        @foreign_keys.each { |foreign_key|
          Orel.execute(foreign_key.alter_statement)
        }
      end
      #def show_create_tables
        #sorted = @tables.sort_by { |t| t.name }
        #sorted.map { |table|
          #Orel.query("SHOW CREATE TABLE #{qt table.name}")[0][1]
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
      def create_statement
        sql = []
        sql << "CREATE TABLE #{qt name}"
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
      def insert_statement(attributes)
        table = Arel::Table.new(@heading.name)
        manager = Arel::InsertManager.new(table.engine);
        manager.into table
        manager.insert attributes.map { |k, v| [table[k], v] }
        manager.to_sql
      end
      def update_statement(attributes, where)
        table = Arel::Table.new(@heading.name)
        manager = Arel::UpdateManager.new(table.engine);
        manager.table table
        manager.set attributes.map { |k, v| [table[k], v] }
        where.each { |k, v|
          manager.where table[k].eq(v)
        }
        manager.to_sql
      end
      def delete_statement(where)
        table = Arel::Table.new(@heading.name)
        manager = Arel::DeleteManager.new(table.engine);
        manager.from table
        where.each { |k, v|
          manager.where table[k].eq(v)
        }
        manager.to_sql
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
        "#{qc @name} #{type_def}"
      end
    end

    class UniqueKey
      include Quoting
      def initialize(name, attributes)
        @name = name
        @attributes = attributes
      end
      def create_statement(table)
        attribute_names = @attributes.map { |a| qc a.name }
        "UNIQUE KEY #{qc @name} (#{attribute_names.join(',')})"
      end
    end

    class ForeignKey
      include Quoting
      def initialize(parent_table_name, parent_attributes, child_table_name, child_attributes)
        @parent_table_name = parent_table_name
        @parent_attributes = parent_attributes
        @child_table_name = child_table_name
        @child_attributes = child_attributes
      end
      def alter_statement
        name = [@child_table_name, @parent_table_name, "fk"].join("_")
        child_attribute_names = @child_attributes.map { |a| qc a.name }
        parent_attribute_names = @parent_attributes.map { |a| qc a.name }
        "ALTER TABLE #{qt @child_table_name} ADD CONSTRAINT #{qc name} FOREIGN KEY (#{child_attribute_names.join(',')}) REFERENCES #{qt @parent_table_name} (#{parent_attribute_names.join(',')}) ON DELETE NO ACTION ON UPDATE NO ACTION"
      end
    end

  end
end
