require 'set'
require 'logger'

require 'arel'
require 'sourcify'

require 'orel/domains'
require 'orel/object'
require 'orel/relation'
require 'orel/sql'
require 'orel/translator'

module Orel
  VERSION = "0.0.0"

  def self.classes
    @classes ||= Set.new
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= Logger.new("/dev/null")
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

  def self.insert(*args)
    connection.insert(*args)
  end

  def self.recreate_database!
    db_name = current_database
    connection.recreate_database(db_name)
    connection.execute("USE #{db_name}")
  end

  def self.create_tables!
    Orel::Translator.create_tables!(classes)
  end

  def self.get_database_structure
    connection.structure_dump.strip
    #classes.map { |klass| klass.sql.show_create_tables }.flatten
  end

end
