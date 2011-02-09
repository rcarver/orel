module Orel
  module Relation

    def arel
      Arel::Table.new(table_name)
    end

    def orel
      @orel ||= Orel.new
    end

    def table_name
      self.name.underscore
    end

    def heading(&block)
      orel.heading = Heading.new(self)
      dsl = HeadingDSL.new(block)
      dsl.apply(orel.heading)
    end

    def migrate
      migrator = Migrator.new(orel.heading.create_statements(table_name))
      migrator.migrate
    end

    Orel = Struct.new(:heading)

    class Migrator
      def initialize(statements)
        @statements = statements
      end
      def migrate
        @statements.each { |s| Arel::Table.engine.connection.execute(s) }
      end
    end

    class Heading
      def initialize(klass)
        @klass = klass
      end
      def set_primary_key(key)
        @primary_key = key
      end
      def create_statements(table_name)
        table = "CREATE TABLE #{table_name}"
        [table] + @primary_key.create_statements(table_name)
      end
    end

    class Key
      def initialize(name)
        @name = name
        @attributes = Set.new
      end
      attr_reader :name
      def <<(attribute)
        @attributes << attribute
      end
      def create_statements(table_name)
        attribute_names = @attributes.map { |a| a.name }
        attrs = @attributes.map { |a| a.create_statements(table_name) }.flatten
        attrs + ["ALTER TABLE #{table_name} ADD PRIMARY KEY #{name} (#{attribute_names.join(',')})"]
      end
      def alter_statements(table_name)
        attribute_names = @attributes.map { |a| a.name }
        attrs = @attributes.map { |a| a.create_statements(table_name) }.flatten
        attrs + ["ALTER TABLE #{table_name} ADD PRIMARY KEY #{name} (#{attribute_names.join(',')})"]
      end
    end

    class Attribute < Struct.new(:name, :domain)
      def create_statements(table_name)
        ["ALTER TABLE #{table_name} ADD COLUMN #{name} #{type_def}"]
      end
      def type_def
        if domain == String
          "varchar(255) NOT NULL"
        else
          raise ArgumentError, "Unknown type #{domain.inspect}"
        end
      end
    end

    class HeadingDSL
      def initialize(block)
        @keys = {}
        instance_eval(&block)
      end
      def apply(heading)
        if pk = @keys.delete(:primary)
          heading.set_primary_key(pk)
        end
      end
      def key(name, type)
        @keys[:primary] ||= Key.new(:pk)
        @keys[:primary] << Attribute.new(name, type)
      end
    end

  end
end
