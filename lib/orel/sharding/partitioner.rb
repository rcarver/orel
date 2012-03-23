module Orel
  module Sharding
    class Partitioner

      def initialize(heading, connection, partitioned_attribute)
        @heading = heading
        @connection = connection
        @partitioned_attribute = partitioned_attribute
        @known_partitions = Set.new
      end

      def suffix_heading(suffix)
        @partition_namer = @heading.namer.clone
        @heading.namer = Orel::Sharding::Namer.new(@heading.namer, suffix)
      end

      def partition_with(&block)
        @shard_block = block
      end

      def get_all_partitions
        @connection.query("SHOW TABLES LIKE '#{@partition_namer.table_name}_%'").flatten.map { |row|
          name = row.to_sym
          unless name == template_table_name
            @known_partitions << name
            Table.new(name, @heading, @connection)
          end
        }.compact
      end

      def get_partition_for_attributes(attributes, create=false)
        partition_name = get_partition_name_for_attributes(attributes)
        create_table(partition_name) if create
        Table.new(partition_name, @heading, @connection)
      end

      attr_reader :partitioned_attribute
      attr_reader :connection

      # TODO: allow a different connection to be used for a shard.
      #def connection_for_shard(attributes)
      #end

      # TODO: allow a different connection to be used for database manipulation.
      #def connection_for_shard_schema(attributes)
      #end

    protected

      def template_table_name
        @template_table_name || @heading.namer.table_name
      end

      def get_partition_name_for_attributes(attributes)
        value = attributes[@partitioned_attribute]
        raise ArgumentError, "Missing value for #{@partitioned_attribute}" unless value
        suffix = @shard_block.call(value)
        Orel::Sharding::Namer.new(@partition_namer, suffix).table_name
      end

      def create_table(name)
        unless @known_partitions.include?(name)
          begin
            @connection.execute "CREATE TABLE #{name} LIKE #{template_table_name}"
            @known_partitions << name
          rescue ActiveRecord::StatementInvalid => e
            if e.message =~ /already exists/
              @known_partitions << name
            else
              raise
            end
          end
        end
      end

    end
  end
end
