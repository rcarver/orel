module Orel
  class Table
    class Select
      include Orel::QueryBatches

      attr_reader :batch_size
      attr_reader :batch_group
      attr_reader :batch_order

      def initialize(select_manager)
        @select_manager = select_manager
      end

      def method_missing(message, *args, &block)
        @select_manager.send(message, *args, &block)
      end
    end
  end
end
