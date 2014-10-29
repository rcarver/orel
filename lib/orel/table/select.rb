module Orel
  class Table
    # Orel::Table::Select adds "batch" query support to Arel::SelectManager,
    # otherwise providing direct access to tables.
    class Select

      def initialize(select_manager)
        @select_manager = select_manager
      end

      # Implement Orel::QueryReader::Options
      include Orel::QueryBatches
      attr_accessor :description

    protected

      def method_missing(message, *args, &block)
        @select_manager.send(message, *args, &block)
      end
    end
  end
end
