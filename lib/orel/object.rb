module Orel
  # Orel::Object is a module that gives any class relational cabilities.
  # In particular, it lets you describe relations that instances of the class
  # can manipulate. Relations are defined through their heading. A heading
  # describes the attributes and keys in a relation. It  also describes
  # references between relations (and more importantly, between the classes
  # that define those relations).
  #
  # Examples
  #
  #     # A User has a first name and a last name. There may be only
  #     # one user with any first name last name combination because
  #     # we've defined those attributes as a key.
  #     class User
  #       include Orel::Object
  #       heading do
  #         key { first_name / last_name }
  #         att :first_name, Orel::Domains::String
  #         att :last_name, Orel::Domains::String
  #       end
  #     end
  #
  #     # A Thing has a name, an incrementing id and belongs to a User.
  #     class Thing
  #       include Orel::Object
  #       heading do
  #         key { id }
  #         att :id, Orel::Domains::Serial
  #         att :name, Orel::Domains::String
  #         ref User
  #       end
  #     end
  #
  module Object

    NoHeadingError = Class.new(StandardError)

    def self.included(base)
      base.extend Orel::Relation
      base.extend ClassMethods
      base.extend ActiveModel::Naming
    end

    module ClassMethods

      # Public: Create and save a new object.
      #
      # Returns an instance of the class this was called on.
      def create(*args)
        object = new(*args)
        object.save
        object
      end
    end

    # Public: Initialize a new object.
    #
    # attributes - A Hash of key/value pairs to use as values on the object.
    #
    def initialize(attributes={})
      @heading = self.class.get_heading
      raise NoHeadingError unless @heading
      @attributes = Attributes.new(@heading, attributes)
      @class_associations = ClassAssociations.new(self.class, @attributes)
      @simple_associations = SimpleAssociations.new(self, self.class.relation_set)
      @operator = Operator.new(@heading, @attributes)
      @validator = Validator.new(self, @heading, @attributes)
    end

    attr_reader :attributes

    # Public: Read associations and attributes.
    #
    # key - Either a Class or a Symbol.
    #       A Class is expected to be an association.
    #       A Symbol is expected to be an attribute name.
    #
    # Returns a value appropriate to the input.
    # Raises an error if an unknown association is requested
    #   or if the attribute is not defined.
    def [](key)
      case key
      when Class: @class_associations[key]
      else
        if @simple_associations.include?(key)
          @simple_associations[key]
        else
          @attributes[key]
        end
      end
    end

    # Public: Modify associations and attributes.
    #
    # key - Either a Class or a Symbol.
    #       A Class is expected to be an association.
    #       A Symbol is expected to be an attribute name.
    # value - The value to set the association or attribute.
    #
    # Returns nothing.
    # Raises an error if an unknown association or attribute
    #   is specified or if the value is inappropriate.
    def []=(key, value)
      if @simple_associations.include?(key)
        @simple_associations[key] = value
      else
        @attributes[key] = value
      end
    end

    # Public: Persist the object's current attributes. If the object has been
    # saved previously, the non-key attributes are updated, else all attributes
    # are stored. If the object defines a Serial key, that attribute will have
    # a value after calling save.
    #
    # Returns nothing.
    def save
      @operator.create_or_update
      @simple_associations.save
    end

    # Public: Stop persisting this object. If the object has never been persisted,
    # this method has no effect.
    #
    # Returns nothing.
    def destroy
      if @operator.persisted?
        @operator.destroy
      end
    end

    # Public: Determine if a record has been saved.
    #
    # Returns a boolean
    def persisted?
      @operator.persisted?
    end

    # Public: Detemine if the record has been destroyed.
    #
    # Returns a boolean.
    def destroyed?
      @operator.destroyed?
    end

    # Public: Determine whether the record is currently valid.
    #
    # Returns a boolean.
    def valid?
      @validator.valid?
    end

    # Public: Get current validation errors.
    #
    # Returns ActiveModel::Errors.
    def errors
      @validator.errors
    end

    # Public: Convert to ActiveModel.
    #
    # Returns itself.
    def to_model
      self
    end

    # Public: Get an array representing the primary key.
    #
    # Returns an Enumerable or nil.
    def to_key
      if persisted?
        primary_key.attributes.map { |a| @attributes[a.name] }
      else
        nil
      end
    end

    # Public: Get a string representing the primary key.
    #
    # Returns a String or nil.
    def to_param
      if persisted?
        primary_key.attributes.map { |a| @attributes[a.name] }.join(',')
      else
        nil
      end
    end

    # Special handling of `id` to do the right thing in spite of Ruby defining Object#id.
    def id
      if @attributes.att?(:id)
        @attributes[:id]
      else
        super
      end
    end

  protected

    def primary_key
      @heading.get_key(:primary)
    end

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

