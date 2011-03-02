module Orel
  module Object

    NoHeadingError = Class.new(StandardError)

    def self.included(base)
      base.extend Orel::Relation
      base.extend ClassMethods
      base.extend ActiveModel::Naming
    end

    module ClassMethods
      def create(*args)
        object = new(*args)
        object.save
        object
      end
    end

    def initialize(attributes={})
      heading = self.class.get_heading
      raise NoHeadingError unless heading
      @attributes = Attributes.new(heading, attributes)
      @operator = Operator.new(heading, @attributes)
      @validator = Validator.new(self, heading, @attributes)
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

    def to_model
      self
    end

    def persisted?
      @operator.persisted?
    end

    def destroyed?
      @operator.destroyed?
    end

    def valid?
      @validator.valid?
    end

    def errors
      @validator.errors
    end

    def to_param
      nil if persisted?
    end

    def to_key
      nil if persisted?
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

