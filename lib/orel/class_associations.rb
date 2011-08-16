module Orel
  # Retrieve objects through their references. Supports one-to-many and
  # many-to-one associations right now.
  class ClassAssociations

    def initialize(klass, attributes)
      @klass = klass
      @attributes = attributes
    end

    attr_accessor :locked_for_query

    def [](klass)
      # Disallow queries if this instance has been locked.
      raise Orel::LockedForQueryError if @locked_for_query

      if parent_reference = @klass.get_heading.get_parent_reference(klass)
        return parent(parent_reference)
      end
      if child_reference = klass.get_heading.get_parent_reference(@klass)
        return children(child_reference)
      end
      raise ArgumentError, "#{klass} is neither a parent nor child association of #{@klass}"
    end

    # NOTE: @attributes must align with the heading we're talking about
    # so this isn't quite right when we deal with child relations.

    def _store(klass, data)
      # ClassAssociations need to maintain a cache of the associated
      # objects. That cache can  be invalidated by a change to
      # @attributes that change the key that define the relationship.
      # Once we have that, we can prepopulate objects into that cache
      # with this method.
      if @klass.get_heading.get_parent_reference(klass)
        # @attributes[klass] = klass.new(data)
      end
      if klass.get_heading.get_parent_reference(@klass)
        # @attributes[klass] << klass.new(data)
      end
    end

  protected

    # select * from users where users.first_name = [thing.first_name] limit 1
    def parent(reference)
      results = reference.parent_class.table.query("#{self.class} Find parent[#{reference.parent_class}] of child[#{reference.child_class}]") { |q, table|
        reference.parent_class.get_heading.attributes.each { |a|
          q.project table[a.name]
        }
        reference.parent_key.attributes.each { |a|
          q.where table[a.name].eq(@attributes[a.to_foreign_key.name])
        }
        q.take 1
      }
      if results.any?
        object = reference.parent_class.new(results.first)
        object.persisted!
        object
      end
    end

    # select * from things where things.first_name = [user.first_name]
    def children(reference)
      results = reference.child_class.table.query("#{self.class} Find children[#{reference.child_class}] of parent[#{reference.parent_class}]") { |q, table|
        reference.child_class.get_heading.attributes.each { |a|
          q.project table[a.name]
        }
        reference.parent_key.attributes.each { |a|
          q.where table[a.to_foreign_key.name].eq(@attributes[a.to_foreign_key.name])
        }
      }
      results.map { |row|
        object = reference.child_class.new(row)
        object.persisted!
        object
      }
    end

  end
end

