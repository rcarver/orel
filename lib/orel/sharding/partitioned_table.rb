module Orel
  module Sharding
    # Decorates a Table so that all operations act on the appropriate shard.
    class PartitionedTable

      def initialize(partitioner)
        @partitioner = partitioner
      end

      def insert(attributes)
        table = @partitioner.get_partition_for_attributes(attributes, true)
        table.insert(attributes)
      end

      def upsert(options)
        table = @partitioner.get_partition_for_attributes(options[:insert], true)
        table.upsert(options)
      end

      def query(description=nil, &block)
        accumulator = PartitionedQuery::PartitionAccumulator.new(@partitioner)
        table_proxy = PartitionedQuery::TableProxy.new(accumulator)
        manager_proxy = PartitionedQuery::SelectManagerProxy.new

        yield manager_proxy, table_proxy

        results = []

        accumulator.get_partitions.each { |table|
          a_table = @partitioner.connection.arel_table(table)
          a_manager = manager_proxy.get_arel_select_manager(a_table)
          a_manager.from a_table
          results.concat @partitioner.connection.execute(a_manager.to_sql, description || "#{self.class} Query #{table.name}").each(:as => :hash, :symbolize_keys => true)
        }

        results
      end

    end
  end
end
