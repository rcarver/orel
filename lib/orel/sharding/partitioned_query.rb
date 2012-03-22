module Orel
  module Sharding
    # A set of classes that wrap Arel syntax in order to capture
    # information about the query in order to perform it against
    # the relevant partitions.
    module PartitionedQuery

      # Accumulates information about the partitioned attributes
      # that we're querying against and then returns the relevant
      # partitions.
      class PartitionAccumulator

        def initialize(partitioner)
          @partitioner = partitioner
          @values = []
        end

        def attr?(name)
          @partitioner.partitioned_attribute == name
        end

        def add_value(name, values)
          @values.concat values
        end

        def get_partitions
          if @values.empty?
            @partitioner.get_all_partitions
          else
            partitions = {}
            @values.each { |value|
              partition = @partitioner.get_partition_for_attributes(@partitioner.partitioned_attribute => value)
              partitions[partition.name] = partition
            }
            partitions.values
          end
        end
      end

      # Quacks like an Arel::SelectManager.
      class SelectManagerProxy

        def initialize
          @commands = []
        end

        def project(*attribute_proxies)
          @commands << ([:project] << attribute_proxies)
        end

        def where(attribute_proxy)
          @commands << [:where, attribute_proxy]
        end

        def get_arel_select_manager(arel_table)
          manager = Arel::SelectManager.new(arel_table.engine)
          @commands.each { |command|
            manager.send(*dereference(arel_table, *command))
          }
          manager
        end

        def dereference(arel_table, *args)
          result = args.map { |arg|
            if arg.is_a?(Array)
              dereference(arel_table, *arg)
            elsif arg.is_a?(AttributeProxy)
              arg.dereference(arel_table)
            else
              arg
            end
          }
        end
      end

      # Quacks like an Arel::Table.
      class TableProxy

        def initialize(partition_accumulator)
          @partition_accumulator = partition_accumulator
        end

        def [](name)
          AttributeProxy.new(@partition_accumulator, name)
        end
      end

      # Quacks like an Arel::Attribute.
      class AttributeProxy

        def initialize(partition_accumulator, name)
          @partition_accumulator = partition_accumulator
          @name = name
          @commands = []
        end

        def method_missing(message, *args, &block)
          if @partition_accumulator.attr?(@name)
            # TODO: only allow sane predicates like eq and in
            # TODO: and ensure that we pass good values here.
            @partition_accumulator.add_value(@name, args.first)
          end
          @commands << ([message] << args)
          self
        end

        def dereference(arel_table)
          attr = Arel::Attribute.new(arel_table, @name)
          @commands.inject(attr) { |node, c| node.send(*c) }
        end
      end

    end
  end
end
