module Orel
  module SchemaGenerator

    # Public: Get the sql statements to generate a schema for
    # some classes.
    #
    # classes - Classes that implement Orel::Relation.
    #
    # Returns an Array of Strings.
    def self.class_creation_statements(classes)
      headings = classes.map { |klass| klass.relation_set.to_a }.flatten
      creation_statements(headings)
    end

    # Public: Get the sql statements to generate a schema for
    # some set of headings.
    #
    # headings - Array of Orel::Relation::Heading.
    #
    # Returns an Array of Strings.
    def self.creation_statements(headings)
      tables = headings.map { |heading|
        Orel::SchemaGenerator::Table.new(heading.namer, heading)
      }

      foreign_keys = headings.map { |heading|
        heading.foreign_keys.map { |foreign_key|
          parent_table = Orel::SchemaGenerator::Table.new(heading.namer, foreign_key.parent_heading)
          child_table = Orel::SchemaGenerator::Table.new(heading.namer, foreign_key.child_heading)
          parent_attributes = foreign_key.parent_key.attributes
          child_attributes = foreign_key.child_key.attributes
          Orel::SchemaGenerator::ForeignKey.new(
            parent_table,
            parent_attributes,
            child_table,
            child_attributes,
            foreign_key.cascade
          )
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
      def foreign_key_constraint_name(*args)
        @relation_namer.foreign_key_constraint_name(*args)
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
      def initialize(parent_table, parent_attributes, child_table, child_attributes, cascade)
        @parent_table = parent_table
        @parent_attributes = parent_attributes
        @child_table = child_table
        @child_attributes = child_attributes
        @cascade = cascade
      end
      def alter_statement
        fk_name = @child_table.foreign_key_constraint_name(@parent_table.name, @parent_attributes.map { |a| a.name })
        child_attribute_names = @child_attributes.map { |a| qc a.name }
        parent_attribute_names = @parent_attributes.map { |a| qc a.name }
        on_delete = "ON DELETE #{@cascade.on_delete}"
        on_update = "ON UPDATE #{@cascade.on_update}"
        "ALTER TABLE #{qt @child_table.name} ADD CONSTRAINT #{qc fk_name} FOREIGN KEY (#{child_attribute_names.join(',')}) REFERENCES #{qt @parent_table.name} (#{parent_attribute_names.join(',')}) #{on_delete} #{on_update}"
      end
    end

  end
end
