module Orel
  module Sharding
    class Partitioner

      def initialize(heading, connection, sharded_attribute)
        @heading = heading
        @connection = connection
        @sharded_attribute = sharded_attribute
      end

      def suffix_heading(suffix)
        @table_namer = @heading.namer.clone
        @heading.namer = Orel::Sharding::Namer.new(@heading.namer, suffix)
      end

      def partition_with(&block)
        @shard_block = block
      end

      def get_partition_for_attributes(attributes, create=false)
        namer = get_namer_for_attributes(attributes)
        create_table(namer) if create
        Table.new(namer.table_name, @heading, @connection)
      end

    protected

      def get_namer_for_attributes(attributes)
        value = attributes[@sharded_attribute]
        raise ArgumentError, "Missing value for #{@sharded_attribute}" unless value
        suffix = @shard_block.call(value)
        Orel::Sharding::Namer.new(@table_namer, suffix)
      end

      # TODO: allow a different connection to be used for a shard.
      #def connection_for_shard(attributes)
      #end

      # TODO: allow a different connection to be used for database manipulation.
      #def connection_for_shard_schema(attributes)
      #end

      def create_table(namer)
        # TODO: we need to create the shard based on the actual template table to
        # account for indices and other table tweak that aren't captured by orel.
        create_shard(@heading.with_namer(namer), @connection)
      end

    protected

      def create_shard(template_heading, connection)
        begin
          Orel::SchemaGenerator.creation_statements([template_heading]).each { |statement|
            connection.execute(statement)
          }
        rescue ActiveRecord::StatementInvalid => e
          raise unless e.message =~ /already exists/
        end
      end

      #def self.create_table_from_template(template_name, table_name)
        #access = MysqlInspector::AR::Access.new(schema_connection)
        #tables = access.tables
        #table = tables.find { |t| t.name.to_s == table_name.to_s }
        #template = tables.find { |t| t.name.to_s == template_name.to_s }
        #if !table
          #table = MysqlInspector::Table.new(template.to_sql)
          #table.name = table_name
          #access.load(table.to_sql)
        #end
      #end

    end
  end
end
