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

  def self.connection
    Arel::Table.engine.connection
  end

  def self.current_database
    connection.current_database
  end

  def self.query(*args)
    connection.select_rows(*args)
  end

  def self.execute(*args)
    connection.execute(*args)
  end

  def self.recreate_database!
    db_name = current_database
    connection.recreate_database(db_name)
    connection.execute("USE #{db_name}")
  end

  def self.create_tables!
    classes.each { |klass|
      klass.sql.create_tables!
    }
  end

  def self.get_database_structure
    connection.structure_dump.strip
    #classes.map { |klass| klass.sql.show_create_tables }.flatten
  end

end
