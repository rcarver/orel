module Orel
  class Table
    class Reader

      def initialize(manager, heading, connection, description = nil)
        @manager = manager
        @heading = heading
        @connection = connection
        @description = description
      end

      def read_all
        read
      end

      def read_batch(start, count)
        @manager.take count
        @manager.skip start

        read
      end

    protected

      def read
        @connection.execute(
          @manager.to_sql,
          @description || "#{self.class} Query #{@heading.name}"
        ).each(:as => :hash, :symbolize_keys => true)
      end
    end
  end
end
