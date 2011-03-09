module Orel
  module Relation

    def self.extended(klass)
      Orel.classes << klass
    end

    # Public: Define a relation heading for this class. See
    # Orel::Relation::HeadingDSL for additional syntax.
    #
    # Examples
    #
    #     heading do
    #       att :name, Orel::Domains::String
    #     end
    #
    # Returns nothing.
    def heading(&block)
      dsl = HeadingDSL.new(self, database, &block)
      dsl._apply!
    end

    # Public: Define the heading for one-to-one child relation. The relation
    # is automatically given a reference to this class's parent relation and
    # a key is defined for that foreign key.
    #
    # child_name - Symbol to name the child.
    #
    # Examples
    #
    #     one :state do
    #       att :status, Orel::Domains::Integer
    #     end
    #
    # Returns nothing.
    def one(child_name, &block)
      dsl = HeadingDSL.new(self, database, child_name, &block)
      dsl.ref self, :unique => true
      dsl._apply!
    end

    # Public: Define the heading for one-to-many child relation. The relation
    # is automatically given a reference to this class's parent relation.
    #
    # child_name - Symbol to name the child.
    #
    # Examples
    #
    #     many :statuses do
    #       att :status, Orel::Domains::Integer
    #     end
    #
    # Returns nothing.
    def many(child_name, &block)
      dsl = HeadingDSL.new(self, database, child_name, &block)
      dsl.ref self
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
