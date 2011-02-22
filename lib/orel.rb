require 'set'
require 'logger'

require 'arel'
require 'sourcify'

require 'orel/algebra'
require 'orel/attributes'
require 'orel/domains'
require 'orel/object'
require 'orel/operator'
require 'orel/relation'
require 'orel/sql'

require 'orel/relation/attribute'
require 'orel/relation/database'
require 'orel/relation/foreign_key'
require 'orel/relation/heading'
require 'orel/relation/heading_dsl'
require 'orel/relation/key'
require 'orel/relation/key_dsl'
require 'orel/relation/reference'

module Orel
  VERSION = "0.0.0"

  def self.classes
    @classes ||= Set.new
  end

  def self.finalize!
    return if @finalized
    @finalized = true
    classes.each { |klass|
      klass.database.headings.each { |heading|
        heading.references.each { |ref|
          ref.create_foreign_key_relationship!
        }
      }
    }
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

  def self.current_database_name
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
    db_name = current_database_name
    connection.recreate_database(db_name)
    connection.execute("USE #{db_name}")
  end

  def self.create_tables!
    finalize!
    Orel::Sql.create_tables!(classes)
  end

  def self.get_database_structure
    connection.structure_dump.strip
    #classes.map { |klass| klass.sql.show_create_tables }.flatten
  end

end
