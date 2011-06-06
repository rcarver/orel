module Orel
  module Relation

    def self.extended(klass)
      Orel.classes << klass
    end

    # Public: Define a relation heading for this class. See
    # Orel::Relation::HeadingDSL for additional syntax.
    #
    # child_name - Symbol name for a simple child relation.
    #              Simple child relations are an easy to way
    #              store information about the main class
    #              in separate relations.
    #
    # Examples
    #
    #     class User
    #       heading do
    #         key { name }
    #         att :name, Orel::Domains::String
    #       end
    #       heading :status do
    #         key { User }
    #         att :type, Orel::Domains::String
    #       end
    #     end
    #
    # Returns nothing.
    def heading(child_name=nil, &block)
      dsl = HeadingDSL.new(self, relation_set, relation_namer, child_name, &block)
      dsl.ref self if child_name
      dsl._apply!
    end

    # Public: Get a table to perform operations on.
    #
    # child_name - Symbol name of the child relation (default: get the parent relation).
    #
    # Returns an Orel::Table.
    # Raises a RuntimeError if a heading cannot be found.
    def get_table(child_name=nil)
      Orel::Table.new(relation_namer, get_heading(child_name))
    end

    # Internal: Get the heading of this relation.
    #
    # child_name - Symbol name of the child relation (default: get the parent relation).
    #
    # Returns an Orel::Relation::Heading.
    # Raises a RuntimeError if a heading cannot be found.
    def get_heading(child_name=nil)
      if child_name
        relation_set.child(child_name) or raise "No child heading #{child_name.inspect}"
      else
        relation_set.base
      end
    end

    def relation_namer
      @namer ||= Orel::Relation::Namer.for_class(self)
    end

    def relation_set
      @relation_set ||= Orel::Relation::Set.new(relation_namer)
    end

    alias_method :headings, :relation_set

  end
end
