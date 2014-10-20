require 'set'
require 'logger'

# Choice bits of ActiveSupport.
require 'active_support/inflector'
require 'active_support/core_ext/module/introspection'

# Orel is ActiveModel compatible.
require 'active_model'

# Arel does the low level relational algebra.
require 'arel'

# Allows fancy `key` syntax.
require 'sourcify'

# Database implementations may not be assumed in the future.
require 'active_record'
require 'mysql2'

require 'orel/version'

require 'orel/attributes'
require 'orel/batch_query'
require 'orel/class_associations'
require 'orel/connection'
require 'orel/domains'
require 'orel/finder'
require 'orel/object'
require 'orel/operator'
require 'orel/options'
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

  AR = ActiveRecord::Base

  def self.logger=(logger)
    AR.logger = logger
  end

  def self.logger
    AR.logger ||= Logger.new("/dev/null")
  end

  def self.recreate_database!
    db_name = Orel::AR.connection.current_database
    Orel::AR.connection.recreate_database(db_name)
    Orel::AR.connection.execute("USE #{db_name}")
  end

  def self.create_tables!
    Orel.finalize!
    Orel::SchemaGenerator.class_creation_statements(classes).each { |statement|
      Orel::AR.connection.execute(statement)
    }
  end

protected

  def self.classes
    @classes ||= Set.new
  end

end
