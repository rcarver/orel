module Orel
  # Retrieve objects through their references. Supports one-to-many and
  # many-to-one associations right now.
  class ClassAssociations

    def initialize(klass, attributes)
      @klass = klass
      @attributes = attributes
      @cache = {}
    end

    attr_accessor :locked_for_query

    def [](klass)

      if reference = @klass.get_heading.get_parent_reference(klass)
        return @cache[[@klass, klass]] ||= parent(reference)
      end
      if reference = klass.get_heading.get_parent_reference(@klass)
        return @cache[[klass, @klass]] ||= children(reference)
      end
      raise ArgumentError, "#{klass} is neither a parent nor child association of #{@klass}"
    end

    # NOTE: @attributes must align with the heading we're talking about
    # so this isn't quite right when we deal with child relations.

    def _store(klass, data)
      if @klass.get_heading.get_parent_reference(klass)
        @cache[[@klass, klass]] = klass.new(data)
      end
      if klass.get_heading.get_parent_reference(@klass)
        @cache[[klass, @klass]] ||= Set.new
        @cache[[klass, @klass]] << klass.new(data)
      end
    end

  protected

    # select * from users where users.first_name = [thing.first_name] limit 1
    def parent(reference)
      raise Orel::LockedForQueryError if @locked_for_query

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
      raise Orel::LockedForQueryError if @locked_for_query

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

