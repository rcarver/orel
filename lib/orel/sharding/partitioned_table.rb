module Orel
  module Sharding
    # Decorates a Table so that all operations act on the appropriate shard.
    class ParitionedTable

      def initialize(partitioner)
        @partitioner = partitioner
      end

      def insert(attributes)
        table = @partitioner.get_partition_for_attributes(attributes, true)
        table.insert(attributes)
      end

      def query(&block)
        []
      end
    end
  end
end
