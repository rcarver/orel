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

    attr_accessor :locked_for_query

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

    def _store(name, data)
      case association = get(name)
      when OneProxy then association._set(data)
      when ManyProxy then association << data
      else raise "Cannot store to a #{association.class}"
      end
    end

  protected

    def get(name)
      unless @associations[name]
        # If a lock is set on this object, disallow any new relationships
        # to be instanciated.
        raise Orel::LockedForQueryError if @locked_for_query

        heading = @relation_set.child(name) or raise InvalidRelation, name
        heading_attrs = heading_pk_attribute_names(heading)
        parent_attrs = parent_pk_attribute_names

        # If the heading's pk is the class's pk, it's a 1:1.
        if parent_attrs == heading_attrs
          @associations[name] = OneProxy.new(@parent.class.relation_namer, @parent, heading)
        else
          @associations[name] = ManyProxy.new(@parent.class.relation_namer, @parent, heading)
        end

        # Populate the instance if this object is persisted.
        @associations[name]._populate! if @parent.persisted?
      end
      @associations[name]
    end

    def heading_pk_attribute_names(heading)
      heading.get_key(:primary).attributes.map { |a| a.name }
    end

    def parent_pk_attribute_names
      @pk_attribute_names ||= @parent.class.get_heading.get_key(:primary).attributes.map { |a| a.to_foreign_key.name }
    end

    module ProxyHelper
      # The primary key names in the parent.
      def _parent_keys
        @_parent_keys ||= _parent.class.get_heading.get_key(:primary).attributes.map { |a| a.to_foreign_key.name }
      end
      def _to_hash(attributes)
        hash = attributes.to_hash
        _parent_keys.each { |k| hash.delete(k) }
        hash
      end
    end

    class Proxy
      # Get a Hash of key/value pairs in the parent's primary key.
      def _parent_key_data
        hash = @parent.class.get_heading.get_key(:primary).attributes.map { |a|
          [a.to_foreign_key.name, @parent[a.name]]
        }
        Hash[*hash.flatten]
      end
      # Query to find existing data belonging to the parent.
      def _find_existing_data(description)
        parent_data = _parent_key_data
        results = Table.new(@heading).query("#{Orel::SimpleAssociations} #{description}") { |q, table|
          @heading.attributes.each { |a|
            q.project table[a.name]
          }
          parent_data .each { |k, v|
            q.where table[k].eq(v)
          }
          yield q, table if block_given?
        }
      end
    end

    class OneProxy < Proxy
      include ProxyHelper

      def initialize(relation_namer, parent, heading)
        @relation_namer = relation_namer
        @parent = parent
        @heading = heading
        @attributes = Attributes.new(@heading)
        @operator = Operator.new(@heading, @attributes)
      end

      # Public: Determine existence of a record.
      #
      # Returns a Boolean.
      def nil?
        @attributes.empty?
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

      def _populate!
        results = _find_existing_data("1:1 parent[#{@parent.class} child[#{@heading.name}]") { |q, table|
          q.take 1
        }
        _set(results.first) if results.any?
      end

    protected

      # All other messages are interpreted as method calls on
      # the underlying record.
      def method_missing(message, *args, &block)
        if nil?
          raise NoMethodError, "The 1:1 association is nil"
        else
          @attributes[message]
        end
      end

      # For ProxyHelper
      def _parent; @parent end
    end

    class ManyProxy < Proxy

      class Record < Struct.new(:_parent, :attributes, :operator)
        include ProxyHelper
        def to_hash
          _to_hash(attributes)
        end
      protected
        def method_missing(message, *args, &block)
          attributes[message]
        end
      end

      def initialize(relation_namer, parent, heading)
        @relation_namer = relation_namer
        @parent = parent
        @heading = heading
        @records = []
      end

      include Enumerable

      # Public: Iterate over the records. Enumerable is supported.
      #
      # Yields a Hash for each record.
      def each
        @records.each { |r| yield r }
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
        @records << Record.new(@parent, attrs, operator)
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

      def _populate!
        results = _find_existing_data("M:1 parent[#{@parent.class}] children[#{@heading.name}]")
        results.each { |r| self << r }
      end
    end

  end
end
