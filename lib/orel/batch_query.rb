module Orel 
  class BatchQuery 

    module Options
      attr_reader :batch_size
      attr_reader :batch_group
      attr_reader :batch_order
    end

    module Batch
      def read_batch(size, count)
      end
      def read_all
      end
    end

    def initialize(batch_options, batch, heading, manager, table)
      @batch_options = batch_options
      @batch = batch
      @heading = heading
      @manager = manager
      @table = table
    end

    def results
      if @batch_options.batch_size
        # Passing start is not supported. Use conditions to specify the start
        # and end position.
        start = 0
        count = @batch_options.batch_size
        group = @batch_options.batch_group
        order = @batch_options.batch_order
        if order
          @heading.attributes.each { |a|
            @manager.order @table[a.name]
          }
        end
        Enumerator.new do |e|
          loop do
            objects = @batch.read_batch(start, count)
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
        @batch.read_all
      end
    end

  end
end
