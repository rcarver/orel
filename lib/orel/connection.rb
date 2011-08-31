module Orel
  class Connection

    def initialize(active_record)
      @active_record = active_record
      @active_record_connection = @active_record.connection
      @arel_tables = {}
    end

    def execute(sql, description=nil)
      begin
        @active_record_connection.execute(sql, description=nil)
      rescue StandardError => e
        debug_sql_error(sql)
        raise
      end
    end

    def insert(sql, description=nil)
      begin
        @active_record_connection.insert(sql, description=nil)
      rescue StandardError => e
        debug_sql_error(sql)
        raise
      end
    end

    def query(sql, description=nil)
      begin
        @active_record_connection.select_rows(sql, description=nil)
      rescue StandardError => e
        debug_sql_error(sql)
        raise
      end
    end

    # Internal
    def arel_table(heading)
      @arel_tables[heading.name] ||= Arel::Table.new(heading.name, @active_record)
    end

  protected

    def debug_sql_error(sql)
      Orel.logger.fatal "A SQL error occurred while executing:\n#{sql}"
    end

  end
end
