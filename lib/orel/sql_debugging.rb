module Orel
  module SqlDebugging

    def debug_sql_error(statement)
      Orel.logger.fatal "A SQL error occurred while executing:\n#{statement}"
    end

  end
end
