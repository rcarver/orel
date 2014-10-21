module Orel
  class Table
    class Batch
      def initialize(manager, heading, connection)
        @connection = connection
        @manager = manager
        @heading = heading
      end

      def read_all
        read
      end

      def read_batch(start, count)
        @manager.take count
        @manager.skip start
        read
      end

      def read
        @connection.execute(@manager.to_sql, @description || "#{self.class} Query #{@heading.name}").each(:as => :hash, :symbolize_keys => true)
      end
    end
  end
end
