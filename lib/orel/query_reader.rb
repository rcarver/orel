module Orel
  # QueryReader defines a consistent interface to configuring and performing
  # queries, used by Orel::Table#query and Orel::Query#query.
  class QueryReader

    # Internal: Interface to define how a query is performed.
    module Options

      # Returns a String.
      attr_reader :description

      # Returns an Integer or nil. Integer determines how many records to
      # include in each batch. Nil means no batching.
      attr_reader :batch_size

      # Returns a Boolean, true if the results should be grouped by batch or
      # each object yielded individually.
      attr_reader :batch_group

      # Returns a Boolean, true if the results should be explicitely ordered by
      # the primary key.
      attr_reader :batch_order
    end

    # Internal: Interface to define how to read results.
    module Reader

      # Returns an Array.
      def read(description)
        raise NotImplementedError
      end
    end

    # Internal: Initialize a new QueryReader.
    #
    # options - Orel::QueryReader::Options.
    # reader  - Orel::QueryReader::Reader.
    #
    def initialize(options, reader, heading, manager, table)
      @options = options
      @reader = reader
      @heading = heading
      @manager = manager
      @table = table
    end

    def read
      if @options.batch_size.nil?
        return @reader.read @options.description
      end

      if @options.batch_order
        set_batch_order
      end

      # Passing start is not supported. Use conditions to specify the start
      # and end position.
      start = 0
      count = @options.batch_size
      group = @options.batch_group

      Enumerator.new do |e|
        loop do
          set_batch_limit(start, count)
          objects = @reader.read describe_batch(start, count)
          start += count
          if objects.empty?
            break
          end
          if group
            e.yield objects
          else
            objects.each do |obj|
              e.yield obj
            end
          end
          if objects.size < count
            break
          end
        end
      end
    end

  protected

    def set_batch_order
      @heading.attributes.each do |a|
        @manager.order @table[a.name]
      end
    end

    def set_batch_limit(start, count)
      @manager.skip start
      @manager.take count
    end

    def describe_batch(start, count)
      "#{@options.description} (batch rows: #{start}-#{start + count})"
    end
  end
end
