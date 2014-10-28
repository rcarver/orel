module Orel
  class Table
    class Reader

      def initialize(select_manager, connection)
        @select_manager = select_manager
        @connection = connection
      end

      # Implements Orel::QueryReader::Reader.
      def read(description)
        @connection.execute(
          @select_manager.to_sql,
          description
        ).each(:as => :hash, :symbolize_keys => true)
      end
    end
  end
end
