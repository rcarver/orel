module Orel
  class Algebra

    # Public: Initialize new Algebra.
    #
    # klass - Class containing a heading to perform algebra on.
    #
    def initialize(klass)
      @klass = klass
      @heading = klass.get_heading
      @table = Arel::Table.new(@heading.name)
      @manager = Arel::SelectManager.new(@table.engine)
      @manager.from @table
    end

    # Public: Project attributes of the resulting relation.
    #
    # TODO: add an arg to set the attributes to project.
    #
    # Returns Orel::Algebra for chaining.
    def project
      @manager.project Arel::Nodes::SqlLiteral.new('*')
      self
    end

    # Public: Restrict the resulting relation with the
    # values of some attributes.
    #
    # attributes - Hash key/value pairs required in the
    #              resulting relation.
    #
    # Returns Orel::Algebra for chaining.
    def restrict(attributes={})
      attributes.each { |k, v|
        @manager.where @table[k].eq(v)
      }
      self
    end

    # Public: Join another class.
    #
    # klass - Class that has a heading containing
    #         a reference to the current class.
    #
    # Returns Orel::Algebra for chaining.
    def join(klass)
      join_heading = klass.get_heading
      join_table = Arel::Table.new(join_heading.name)

      join_reference = join_heading.get_child_reference(klass)
      raise "Missing reference #{klass} for #{@klass}" unless join_reference

      parent_key = join_reference.parent_key
      child_key = join_reference.child_key

      @manager.join(join_table)

      predicates = parent_key.attributes.map { |parent_attribute|
        child_attribute = parent_attribute.to_foreign_key
        join_table[child_attribute.name].eq(@table[parent_attribute.name])
      }
      @manager.on(*predicates)

      self
    end

    # Public: Get the sql statement for the algebra.
    #
    # Returns a String.
    def to_sql
      @manager.to_sql
    end

    # Public: Execute the current algebraic statement and iterate
    # over the results.
    #
    # block - Proc that receives a tuple for each row in the resulting
    #         relation. The tuple has symbol keys for each attribute
    #         in the current projection.
    #
    # Returns nothing.
    def each(&block)
      begin
        Orel.execute(to_sql).each(:as => :hash, :symbolize_keys => true, &block)
      rescue StandardError => e
        debug_sql_error(statement)
        raise
      end
    end

  protected

    def debug_sql_error(statement)
      Orel.logger.fatal "A SQL error occurred while executing:\n#{statement}"
    end

  end
end