module Orel
  class Connection

    def initialize(active_record_connection)
      @active_record_connection = active_record_connection
    end

    def execute(*args)
      @active_record_connection.execute(*args)
    end

    def insert(*args)
      @active_record_connection.insert(*args)
    end

    def query(*args)
      @active_record_connection.select_rows(*args)
    end

  end
end
