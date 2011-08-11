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
        pk_attrs = class_pk_attribute_names
        # If the heading's pk is the class's pk and more, it's a M:1.
        if (heading_attrs & pk_attrs).size == pk_attrs.size && heading_attrs.size > pk_attrs.size
          @associations[name] = ManyProxy.new(@parent.class.relation_namer, @parent, heading)
        else
          @associations[name] = OneProxy.new(@parent.class.relation_namer, @parent, heading)
        end
      end
      @associations[name]
    end

    def heading_pk_attribute_names(heading)
      heading.get_key(:primary).attributes.map { |a| a.name }
    end

    def class_pk_attribute_names
      @pk_attribute_names ||= @parent.class.get_heading.get_key(:primary).attributes.map { |a| a.name }
    end

    class OneProxy

      def initialize(relation_namer, parent, heading)
        @relation_namer = relation_namer
        @parent = parent
        @heading = heading
        @attributes = Attributes.new(@heading)
        @operator = Operator.new(@heading, @attributes)
      end

      def _set(attributes)
        attributes.each { |k, v| @attributes[k] = v }
      end

      def _save
        @attributes[@parent.class] = @parent
        @operator.create_or_update
      end

    protected

      def method_missing(message, *args, &block)
        @attributes[message]
      end
    end

    class ManyProxy

      Record = Struct.new(:attributes, :operator)

      def initialize(relation_namer, parent, heading)
        @relation_namer = relation_namer
        @parent = parent
        @heading = heading
        @records = []
      end

      include Enumerable

      def each
        @records.each { |r| yield r.attributes.hash }
      end

      def size
        @records.size
      end

      def to_a
        @records.map { |r| r.attributes.hash }
      end

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
