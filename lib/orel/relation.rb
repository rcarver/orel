module Orel
  module Relation

    def self.extended(klass)
      Orel.classes << klass
    end

    def heading(&block)
      dsl = HeadingDSL.new(self, block)
      dsl._apply(database)
    end

    def one(child_name, &block)
      dsl = HeadingDSL.new(self, block)
      dsl.ref self, child_name, :unique => true
      dsl._apply(database, child_name)
    end

    def many(child_name, &block)
      dsl = HeadingDSL.new(self, block)
      dsl.ref self, child_name
      dsl._apply(database, child_name)
    end

    # Internal: Get the name of this relation.
    #
    # sub_name - Symbol name of the sub-relation (default: get the base relation).
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
