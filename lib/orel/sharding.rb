module Orel
  # An extension to Orel::Relation that transparently stores and retrieves
  # data from multiple database tables for one logical heading.
  module Sharding

    def self.extended(base)
      #raise ArgumentError, "Orel::Sharding is not supported for Orel::Object"
      base.class_eval do
        extend Orel::Relation
      end
    end

    # Public: Partition records in this heading into multiple underlying tables.
    #
    # attribute - Symbol name of the attribute to partition on.
    # block     - A block that takes the attribute and returns the
    #             shard identifier as a String.
    #
    # Examples
    #
    #     shard_table_on(:day) do |day|
    #       day.strftime("%Y%m") # shard by month
    #     end
    #
    # Returns nothing.
    def shard_table_on(attribute, &block)
      heading = get_heading
      @shard_partitioner = Orel::Sharding::Partitioner.new(heading, connection, attribute)
      @shard_partitioner.suffix_heading("template")
      @shard_partitioner.partition_with(&block)
      nil
    end

    # Public: Get access to a logical table which represents all partitions.
    #
    # child_name - Symbol name of the child table (default: the base table).
    #
    # Returns an Orel::Sharding::ParitionedTable.
    def table(child_name=nil)
      raise ArgumentError, "Child table is not supported" if child_name
      Sharding::PartitionedTable.new(@shard_partitioner)
    end

    # Public: Get access to a single table partition.
    #
    # attributes - Hash of attributes that must at least contain
    #              values for the keys used to partition.
    #
    # Returns an Orel::Table.
    def partition_for(attributes)
      @shard_partitioner.get_partition_for_attributes(attributes, false)
    end

    attr_reader :shard_partitioner

  end
end
