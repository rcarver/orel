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
      dsl = HeadingDSL.new(self, database, child_name, &block)
      dsl.ref self if child_name
      dsl._apply!
    end

    # Internal: Get the name of this relation.
    #
    # sub_name - Symbol name of the sub-relation (default: get the parent relation).
    #
    # Returns a String.
    def relation_name(sub_name=nil)
      database.relation_name(sub_name)
    end

    # Internal: Get the heading of this relation.
    #
    # child_name - Symbol name of the child relation (default: get the parent relation).
    #
    # Returns an Orel::Relation::Heading or nil.
    def get_heading(sub_name=nil)
      database.get_heading(sub_name)
    end

    # Internal: Get the set of relations defined by this class.
    #
    # Returns an Orel::Relation::Database.
    def database
      @database ||= Orel::Relation::Database.new(self)
    end

  end
end
