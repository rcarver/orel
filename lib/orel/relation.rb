module Orel
  # The class level DSL that defines `heading` and other class
  # methods such as `table`. This module may be extended by any
  # class in order to gain access to these methods without the
  # need for a full Orel::Object.
  module Relation

    def self.extended(klass)
      Orel.classes << klass
    end

    # Public: Get the database connection for this class. Each
    # Orel::Relation uses separate instance of ActiveRecord::Base,
    # which is subclassed from either ActiveRecord::Base itself,
    # or an ActiveRecord::Base subclass found by Orel::Options.
    #
    # Returns an Orel::Connection.
    def connection
      @connection ||= begin
        active_record = Class.new(_orel_options.active_record)
        Orel::Connection.new(active_record)
      end
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
      dsl.ref self, :cascade => true if child_name
      dsl._apply!
    end

    # Public: Get a table to perform operations on.
    #
    # child_name - Symbol name of the child relation (default: get the parent relation).
    #
    # Returns an Orel::Table.
    # Raises a RuntimeError if a heading cannot be found.
    def table(child_name=nil)
      Orel::Table.new(get_heading(child_name), connection)
    end

    # Internal: Get the heading of this relation.
    #
    # child_name - Symbol name of the child relation (default: get the parent relation).
    #
    # Returns an Orel::Relation::Heading.
    # Raises a RuntimeError if a heading cannot be found.
    def get_heading(child_name=nil)
      if child_name
        relation_set.child(child_name) or raise "#{self.name} has no heading #{child_name.inspect}"
      else
        relation_set.base
      end
    end

    def relation_namer
      # TODO: we could make the namer configurable via orel options.
      @namer ||= Orel::Relation::Namer.for_class(self, _orel_options)
    end

    def relation_set
      @relation_set ||= Orel::Relation::Set.new(relation_namer)
    end

    alias_method :headings, :relation_set

    def _orel_options
      @_orel_options ||= Orel::Options.new(self)
    end

  end
end
