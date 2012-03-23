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

        def add_value(name, *values)
          @values.concat Array(values).flatten
        end

        def get_partitions
          all_partitions = @partitioner.get_all_partitions
          if @values.empty?
            all_partitions
          else
            chosen_partitions = @values.map { |value|
              @partitioner.get_partition_for_attributes(@partitioner.partitioned_attribute => value)
            }
            all_partitions & chosen_partitions
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

        # The predicate functions that are sane to perform on
        # a partitioned attribute.
        PREDICATES = [
          :eq, :in
        ]

        def initialize(partition_accumulator, name)
          @partition_accumulator = partition_accumulator
          @name = name
          @commands = []
        end

        def method_missing(message, *args, &block)
          if @partition_accumulator.attr?(@name)
            unless PREDICATES.include?(message)
              raise ArgumentError, "Partitioned attributes may only be constrained with [#{PREDICATES.join(', ')}]"
            end
            @partition_accumulator.add_value(@name, args.first)
          end
          @commands.push :message => message, :args => args
          self
        end

        def dereference(arel_table)
          attr = Arel::Attribute.new(arel_table, @name)
          @commands.inject(attr) { |node, c| node.send c[:message], *c[:args] }
        end
      end

    end
  end
end
