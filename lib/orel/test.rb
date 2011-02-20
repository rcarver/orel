require 'orel'
require 'active_record'
require 'mysql2'
require 'stringio'

Orel.logger = Logger.new(File.dirname(__FILE__) + "/../../log/test.log")
Orel.logger.info "\n\nBeginning test #{Time.now}\n"

Arel::Table.engine = ActiveRecord::Base

ActiveRecord::Base.logger = Orel.logger
ActiveRecord::Base.establish_connection(
  :adapter => 'mysql2',
  :database => 'orel_test',
  :username => 'root',
  :password => ''
)


class ActiveRecord::ConnectionAdapters::Mysql2Adapter
  def primary_keys(table) #:nodoc:
    keys = []
    result = execute("describe #{quote_table_name(table)}")
    result.each do |h|
      #keys << h["Field"] if h["Key"] == "PRI"
      keys << h[0] if h[3] == "PRI"
    end
    #result.free
    keys
  end
end

module Arel
  class Table
    def primary_keys
      @primary_keys ||= begin
        primary_key_names = @engine.connection.primary_keys(name)
        primary_key_names.map { |k| self[k] }
      end
    end
  end
end

module Orel
  module Test

    # Print '---' before and after the block is executed.
    def self.wrap
      puts '---'
      yield
      puts '---'
    end

    # Print '---' before and after the block is executed,
    # and also sort anything written to stdout within the
    # block. This is to deal with the fact that relations
    # are not ordered, but we need ordered output to
    # check with simple string comparisons.
    def self.wrap_and_sort
      puts '---'
      out = $stdout
      str = String.new
      begin
        $stdout = StringIO.new(str)
        yield
      ensure
        $stdout = out
        str.split("\n").sort.each { |line|
          puts line
        }
      end
      puts '---'
    end

    # Print '---' before and after the results of
    # a sql query.
    def self.show(*args)
      wrap {
        Orel.query(*args).each { |row|
          puts row.join(',')
        }
      }
    end
  end
end
