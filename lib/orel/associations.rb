module Orel
  # Retrieve objects through their references. Supports one-to-many and
  # many-to-one associations right now.
  class Associations

    InvalidReference = Class.new(ArgumentError)

    def initialize(klass, attributes)
      @klass = klass
      @attributes = attributes
    end

    def [](klass)
      if parent_reference = @klass.get_heading.get_parent_reference(klass)
        return parent(parent_reference)
      end
      if child_reference = klass.get_heading.get_parent_reference(@klass)
        return children(child_reference)
      end
      raise ArgumentError, "#{klass} is neither a parent nor child association"
    end

    # NOTE: @attributes must align with the heading we're talking about
    # so this isn't quite right when we deal with child relations.

  protected

    # select * from users where users.first_name = [thing.first_name] limit 1
    def parent(reference)
      parent_class = reference.parent_class
      parent_key = reference.parent_key
      algebra = Orel::Algebra.new(parent_class)

      parent_key.attributes.each { |parent_attribute|
        child_attribute = parent_attribute.to_foreign_key
        algebra.restrict(parent_attribute.name => @attributes[child_attribute.name])
      }
      algebra.project
      # TODO: set a limit on the algebra
      algebra.map { |row| parent_class.new(row) }.first
    end

    # select * from things where things.first_name = [user.first_name]
    def children(reference)
      child_class = reference.child_class
      parent_key = reference.parent_key
      algebra = Orel::Algebra.new(child_class)

      parent_key.attributes.each { |parent_attribute|
        child_attribute = parent_attribute.to_foreign_key
        algebra.restrict(parent_attribute.name => @attributes[child_attribute.name])
      }
      algebra.project
      algebra.map { |row| child_class.new(row) }
    end

  end
end

