module Orel
  module Object

    def self.included(base)
      base.extend Orel::Relation
    end

    def initialize(attributes={})
      heading = self.class.get_heading
      @attributes = Attributes.new(heading, attributes)
      @operator = Operator.new(heading, @attributes)
    end

    attr_reader :attributes

    def id
      if @attributes.att?(:id)
        @attributes[:id]
      else
        super
      end
    end

    def save
      if @operator.persisted?
        @operator.update
      else
        @operator.create
      end
    end

    def destroy
      if @operator.persisted?
        @operator.destroy
      end
    end

  protected

    def method_missing(message, *args, &block)
      key, action = @attributes.extract_method_missing(message, args)
      if key && action
        case action
        when :get: @attributes[key]
        when :set: @attributes[key] = args.first
        end
      else
        super
      end
    end

  end
end

