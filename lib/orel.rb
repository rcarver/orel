require 'set'
require 'logger'

require 'arel'
require 'active_model'
require 'active_support/inflector'
require 'sourcify'

# Database implementations may not be assumed in the future.
require 'active_record'
require 'mysql2'

require 'orel/sql_debugging'
require 'orel/algebra'
require 'orel/attributes'
require 'orel/class_associations'
require 'orel/domains'
require 'orel/object'
require 'orel/operator'
require 'orel/relation'
require 'orel/simple_associations'
require 'orel/sql_generator'
require 'orel/table'
require 'orel/validator'

require 'orel/relation/attribute'
require 'orel/relation/foreign_key'
require 'orel/relation/heading'
require 'orel/relation/heading_dsl'
require 'orel/relation/key'
require 'orel/relation/key_dsl'
require 'orel/relation/namer'
require 'orel/relation/reference'
require 'orel/relation/set'

module Orel
  VERSION = "0.0.0"

  def self.classes
    @classes ||= Set.new
  end

  def self.finalize!
    return if @finalized
    @finalized = true
    classes.each { |klass|
      klass.headings.each { |heading|
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
    Orel::SqlGenerator.creation_statements(classes).each { |statement|
      Orel.execute(statement)
    }
  end

  def self.get_database_structure
    connection.structure_dump.strip
    #classes.map { |klass| klass.sql.show_create_tables }.flatten
  end

end
