module Orel
  class Table
    # Orel::Table::Select adds "batch" query support to Arel::SelectManager,
    # otherwise providing direct access to tables.
    class Select
      include Orel::QueryBatches

      def initialize(select_manager)
        @select_manager = select_manager
      end

    protected

      def method_missing(message, *args, &block)
        @select_manager.send(message, *args, &block) if @select_manager
      end
    end
  end
end
