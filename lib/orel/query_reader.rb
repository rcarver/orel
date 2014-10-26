module Orel
  class QueryReader

    # Interface for defining batch results.
    module Options
      attr_reader :batch_size
      attr_reader :batch_group
      attr_reader :batch_order
    end

    # Interface for reading the results of a query, either in whole or batches.
    module Reader
      def read_all
      end
      def read_batch(size, count)
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

    def results
      if @options.batch_size
        # Passing start is not supported. Use conditions to specify the start
        # and end position.
        start = 0
        count = @options.batch_size
        group = @options.batch_group
        order = @options.batch_order
        if order
          @heading.attributes.each { |a|
            @manager.order @table[a.name]
          }
        end
        Enumerator.new do |e|
          loop do
            objects = @reader.read_batch(start, count)
            start += count
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
      else
        @reader.read_all
      end
    end

  end
end
