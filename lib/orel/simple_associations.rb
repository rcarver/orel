module Orel
  class SimpleAssociations

    InvalidRelation = Class.new(ArgumentError)

    # Internal: Initialize a new SimpleAssociations
    #
    # parent   - Orel::Object that is the parent.
    # database - Orel::Relation::Database in which to find headings.
    #
    def initialize(parent, database)
      @parent = parent
      @database = database
      @associations = {}
    end

    # Public: Determine if a simple association is defined.
    #
    # name - Symbol name of the association.
    #
    # Returns a boolean.
    def include?(name)
      !! @database.get_heading(name)
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
      one(name).set(attributes)
      nil
    end

    # Public: Retrieve a many-to-many association.
    #
    # name - Symbol name of the association.
    #
    # Returns an Orel::SimpleAssociations::ManyProxy.
    def [](name)
      many(name)
    end

    # Internal: Persist all new association values.
    #
    # Returns nothing.
    def save
      @associations.values.each { |a| a.save }
    end

  protected

    def one(name)
      unless @associations[name]
        heading = @database.get_heading(name) or raise InvalidRelation, name
        @associations[name] = OneProxy.new(@parent, heading)
      end
      @associations[name]
    end

    def many(name)
      unless @associations[name]
        heading = @database.get_heading(name) or raise InvalidRelation, name
        @associations[name] = ManyProxy.new(@parent, heading)
      end
      @associations[name]
    end

    class OneProxy

      def initialize(parent, heading)
        @parent = parent
        @heading = heading
        @attributes = Attributes.new(@heading)
        @operator = Operator.new(@heading, @attributes)
      end

      def set(attributes)
        attributes.each { |k, v| @attributes[k] = v }
      end

      def save
        @attributes[@parent.class] = @parent
        @operator.create_or_update
      end
    end

    class ManyProxy

      Record = Struct.new(:attributes, :operator)

      def initialize(parent, heading)
        @parent = parent
        @heading = heading
        @records = []
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

      def save
        @records.each { |record|
          record.attributes[@parent.class] = @parent
          record.operator.create_or_update
        }
      end
    end

  end
end
