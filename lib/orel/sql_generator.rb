module Orel
  module SqlGenerator

    # Internal: Get the sql statements to generate a schema for
    # some set of classes.
    #
    # classes - Array of classes that implment Orel::Relation.
    #
    # Returns an Array of Strings.
    def self.creation_statements(classes)
      tables = classes.map { |klass|
        klass.headings.map { |heading|
          Orel::SqlGenerator::Table.new(heading.namer, heading)
        }
      }

      foreign_keys = classes.map { |klass|
        klass.headings.map { |heading|
          heading.foreign_keys.map { |foreign_key|
            parent_table = Orel::SqlGenerator::Table.new(heading.namer, foreign_key.parent_heading)
            child_table = Orel::SqlGenerator::Table.new(heading.namer, foreign_key.child_heading)
            parent_attributes = foreign_key.parent_key.attributes
            child_attributes = foreign_key.child_key.attributes
            Orel::SqlGenerator::ForeignKey.new(
              parent_table,
              parent_attributes,
              child_table,
              child_attributes
            )
          }
        }
      }

      statements = []
      statements.concat tables.flatten.map { |table| table.create_statement }
      statements.concat foreign_keys.flatten.map { |foreign_key| foreign_key.alter_statement }
      statements
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

    class Table
      include Quoting
      def initialize(relation_namer, heading)
        @relation_namer = relation_namer
        @heading = heading
      end
      attr_reader :relation_namer
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
          UniqueKey.new(
            @relation_namer.unique_key_name(key.attributes.map { |a| a.name }),
            key.attributes
          )
        }
      end
      def foreign_key_constraint_name(table_name)
        @relation_namer.foreign_key_constraint_name(name, table_name)
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
        manager.insert ordered_hash(attributes).map { |k, v| [table[k], v] }
        manager.to_sql
      end
      def upsert_statement(attributes, update)
        values = update[:values] or raise ArgumentError, "Missing :values to update"
        update_with = update[:with] or raise ArgumentError, "Missing :with describing how to update"
        values.all? { |v| attributes.key?(v) } or raise ArgumentError, "All :values to update must have attributes to insert"
        update_statement = case update_with
        when :increment
          values.map { |v| "#{v}=#{v}+VALUES(#{v})" }.join(',')
        when :replace
          values.map { |v| "#{v}=VALUES(#{v})" }
        else
          raise ArgumentError, "Unknown value for :with - #{with.inspect}"
        end
        "#{insert_statement(attributes)} ON DUPLICATE KEY UPDATE #{update_statement}"
      end
      def update_statement(attributes, where)
        table = Arel::Table.new(@heading.name)
        manager = Arel::UpdateManager.new(table.engine)
        manager.table table
        manager.set ordered_hash(attributes).map { |k, v| [table[k], v] }
        where.each { |k, v|
          manager.where table[k].eq(v)
        }
        manager.to_sql
      end
      def delete_statement(where)
        table = Arel::Table.new(@heading.name)
        manager = Arel::DeleteManager.new(table.engine)
        manager.from table
        ordered_hash(where).each { |k, v|
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
      def initialize(parent_table, parent_attributes, child_table, child_attributes)
        @parent_table = parent_table
        @parent_attributes = parent_attributes
        @child_table = child_table
        @child_attributes = child_attributes
      end
      def alter_statement
        name = @child_table.foreign_key_constraint_name(@parent_table.name)
        child_attribute_names = @child_attributes.map { |a| qc a.name }
        parent_attribute_names = @parent_attributes.map { |a| qc a.name }
        "ALTER TABLE #{qt @child_table.name} ADD CONSTRAINT #{qc name} FOREIGN KEY (#{child_attribute_names.join(',')}) REFERENCES #{qt @parent_table.name} (#{parent_attribute_names.join(',')}) ON DELETE NO ACTION ON UPDATE NO ACTION"
      end
    end

  end
end
