require 'set'
require 'logger'

require 'active_support/inflector'
require 'active_model'
require 'arel'
require 'sourcify'

# Database implementations may not be assumed in the future.
require 'active_record'
require 'mysql2'

require 'orel/sql_debugging'
require 'orel/attributes'
require 'orel/class_associations'
require 'orel/domains'
require 'orel/finder'
require 'orel/object'
require 'orel/operator'
require 'orel/relation'
require 'orel/schema_generator'
require 'orel/simple_associations'
require 'orel/query'
require 'orel/table'
require 'orel/validator'

require 'orel/relation/attribute'
require 'orel/relation/cascade'
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

  # Public: Exception thrown if an association is queried on an object
  # that has been marked as locked from querying.
  LockedForQueryError = Class.new(RuntimeError)

  # Public: Exception thrown if an object or association is written
  # to when it has been marked as readonly.
  ReadonlyError = Class.new(RuntimeError)

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
    active_record_base.logger = logger
  end

  def self.logger
    active_record_base.logger ||= Logger.new("/dev/null")
  end

  def self.active_record_base=(klass)
    @active_record_base = klass
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
    Orel::SchemaGenerator.class_creation_statements(classes).each { |statement|
      Orel.execute(statement)
    }
  end

  def self.get_database_structure
    connection.structure_dump.strip
  end

  # Internal
  def self.arel_table(heading)
    @arel_tables ||= {}
    @arel_tables[heading.name] ||= Arel::Table.new(heading.name, active_record_base)
  end

  def self.active_record_base
    @active_record_base ||= ActiveRecord::Base
  end

protected

  def self.classes
    @classes ||= Set.new
  end

  def self.connection
    active_record_base.connection
  end

end
