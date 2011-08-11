module Orel
  class SimpleAssociations

    InvalidRelation = Class.new(ArgumentError)

    # Internal: Initialize a new SimpleAssociations
    #
    # parent       - Orel::Object that is the parent.
    # relation_set - Orel::Relation::Set in which to find headings.
    #
    def initialize(parent, relation_set)
      @parent = parent
      @relation_set = relation_set
      @associations = {}
    end

    # Public: Determine if a simple association is defined.
    #
    # name - Symbol name of the association.
    #
    # Returns a boolean.
    def include?(name)
      !! @relation_set.child(name)
    end

    # Public: Modify the attributes of a one-to-one association.
    #
    # name       - Symbol name of the association.
    # attributes - Hash of key/value pairs to store. If there is no
    #              existing data in the relation, it it stored. Otherwise
    #              the existing data is updated.
    #
    # Returns nothing.
    def []=(name, attributes)
      get(name)._set(attributes)
      nil
    end

    # Public: Retrieve a many-to-many association.
    #
    # name - Symbol name of the association.
    #
    # Returns an Orel::SimpleAssociations::ManyProxy.
    def [](name)
      get(name)
    end

    # Internal: Persist all new association values.
    #
    # Returns nothing.
    def save
      @associations.values.each { |a| a._save }
    end

  protected

    def get(name)
      unless @associations[name]
        heading = @relation_set.child(name) or raise InvalidRelation, name
        heading_attrs = heading_pk_attribute_names(heading)
        parent_attrs = parent_pk_attribute_names
        # If the heading's pk is the class's pk, it's a 1:1.
        if parent_attrs == heading_attrs
          @associations[name] = OneProxy.new(@parent.class.relation_namer, @parent, heading)
        else
          @associations[name] = ManyProxy.new(@parent.class.relation_namer, @parent, heading)
        end
      end
      @associations[name]
    end

    def heading_pk_attribute_names(heading)
      heading.get_key(:primary).attributes.map { |a| a.name }
    end

    def parent_pk_attribute_names
      @pk_attribute_names ||= heading_pk_attribute_names(@parent.class.get_heading)
    end

    class Proxy
      def _parent_keys
        @_parent_keys ||= @parent.class.get_heading.get_key(:primary).attributes.map { |a| a.name }
      end
      def _to_hash(attributes)
        hash = attributes.hash
        _parent_keys.each { |k| hash.delete(k) }
        hash
      end
    end

    class OneProxy < Proxy

      def initialize(relation_namer, parent, heading)
        @relation_namer = relation_namer
        @parent = parent
        @heading = heading
        @attributes = Attributes.new(@heading)
        @operator = Operator.new(@heading, @attributes)

        # Populate from existing data if the record is persisted.
        if @parent.persisted?
          attrs = Hash[*@parent.class.get_heading.get_key(:primary).attributes.map { |a| [a.name, @parent[a.name]] }.flatten]
          results = Table.new(@heading).query { |q, table|
            @heading.attributes.each { |a| q.project table[a.name] }
            attrs.each { |k, v| q.where table[k].eq(v) }
            q.take 1
          }
          _set(results.first) if results.any?
        end
      end

      # Public: Determine existence of a record.
      #
      # Returns a Boolean.
      def nil?
        @attributes.hash.empty?
      end

      # Public: Get the data of the record.
      #
      # Returns a Hash.
      def to_hash
        _to_hash(@attributes)
      end

      def _set(attributes)
        attributes.each { |k, v| @attributes[k] = v }
      end

      def _save
        @attributes[@parent.class] = @parent
        @operator.create_or_update
      end

    protected

      # All other messages are interpreted as method calls on
      # the underlying record.
      def method_missing(message, *args, &block)
        @attributes[message]
      end
    end

    class ManyProxy < Proxy

      Record = Struct.new(:attributes, :operator)

      def initialize(relation_namer, parent, heading)
        @relation_namer = relation_namer
        @parent = parent
        @heading = heading
        @records = []

        # Populate from existing data if the record is persisted.
        if @parent.persisted?
          attrs = Hash[*@parent.class.get_heading.get_key(:primary).attributes.map { |a| [a.name, @parent[a.name]] }.flatten]
          results = Table.new(@heading).query { |q, table|
            @heading.attributes.each { |a| q.project table[a.name] }
            attrs.each { |k, v| q.where table[k].eq(v) }
          }
          results.each { |r| self << r }
        end
      end

      include Enumerable

      # Public: Iterate over the records. Enumerable is supported.
      #
      # Yields a Hash for each record.
      def each
        @records.each { |r| yield _to_hash(r.attributes) }
      end

      # Public: Get the records as an Array.
      #
      # Returns an Array of Hash.
      def to_a
        @records.map { |r| _to_hash(r.attributes) }
      end

      # Public: Get the number of records.
      #
      # Returns an Integer.
      def size
        @records.size
      end

      # Public: Determine emptiness.
      #
      # Returns a Boolean.
      def empty?
        @records.empty?
      end

      # Public: Add a new record to the simple association.
      #
      # attributes - Hash of key/value pairs to store as a new record
      #              in the relation.
      #
      # Returns nothing.
      def <<(attributes)
        attrs = Attributes.new(@heading, attributes)
        operator = Operator.new(@heading, attrs)
        @records << Record.new(attrs, operator)
        nil
      end

      def _set(*args)
        raise "You called _set on a M:1 simple association."
      end

      def _save
        @records.each { |record|
          record.attributes[@parent.class] = @parent
          record.operator.create_or_update
        }
      end

    end

  end
end
