module Orel
  class SimpleAssociations

    InvalidRelation = Class.new(ArgumentError)

    def initialize(parent, database, attributes)
      @parent = parent
      @database = database
      @attributes = attributes
      @associations = {}
    end

    def include?(name)
      !! @database.get_heading(name)
    end

    def []=(name, attributes)
      one(name).set(attributes)
      nil
    end

    def [](name)
      many(name)
    end

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

      def <<(attributes)
        attrs = Attributes.new(@heading, attributes)
        operator = Operator.new(@heading, attrs)
        @records << Record.new(attrs, operator)
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
