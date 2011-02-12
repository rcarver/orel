require 'set'
require 'arel'

require 'orel/domains'
require 'orel/relation'
require 'orel/sql'

module Orel
  VERSION = "0.0.0"

  def self.classes
    @classes ||= Set.new
  end

  def self.query(*args)
    Arel::Table.engine.connection.select_rows(*args)
  end

  def self.execute(*args)
    Arel::Table.engine.connection.execute(*args)
  end

  def self.drop_tables!
    classes.each { |klass|
      klass.sql.drop_tables!
    }
  end

  def self.create_tables!
    classes.each { |klass|
      klass.sql.create_tables!
    }
  end

  def self.show_create_tables
    classes.map { |klass| klass.sql.show_create_tables }.flatten
  end

  def self.migrate
    # noop for now
  end

end
