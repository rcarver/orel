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

    class InvalidRecord < StandardError
      def initialize(object, errors)
        @object = object
        @errors = errors
      end
      attr_reader :object
      attr_reader :errors
      def message
        msgs = []
        @errors.each { |attr, messages|
          msgs << "#{attr}: #{messages.inspect}"
        }
        "Errors on #{object.class}: " + msgs.join(", ")
      end
    end

    def self.included(base)
      base.extend Orel::Relation
      base.extend ClassMethods
      base.extend ActiveModel::Naming
    end

    module ClassMethods

      # Public: Create and save a new object.
      #
      # Examples
      #
      #     user = User.create(:first_name => "John", :last_name => "Smith")
      #
      # Returns an instance of the class. This object is NOT guaranteed
      #   to be valid or pesisted.
      def create(*args)
        object = new(*args)
        object.save
        object
      end

      # Public: Create and persist a new object but raise an exception
      # if the object is not valid.
      #
      # attributes - Hash of name/value pairs to build the object with.
      #
      # Examples
      #
      #     user = User.create!(:first_name => "John", :last_name => "Smith")
      #
      # Returns an instance of the class.
      # Raises Orel::Object::InvalidRecord if the object is not valid.
      def create!(*args)
        object = new(*args)
        object.save or raise InvalidRecord.new(object, object.errors)
        object
      end

      # Public: Find a single record by its primary key. Supports arguments
      # of the Hash or Ordered variety.
      #
      # Hash arguments
      #
      # attributes - Hash of name/value pairs for each attribute in the
      #              primary key.
      #
      # Ordered arguments
      #
      # *args - Array of values that are ordered by the attributes in the
      #         primary key.
      #
      # Examples
      #
      #     # Hash arguments
      #     User.find_by_primary_key(:first_name => "John", :last_name => "Doe")
      #
      #     # Ordered arguments
      #     User.find_by_primary_key("John", "Doe")
      #
      # Returns an Orel::Object or nil.
      def find_by_primary_key(*args)
        _finder.find_by_key(:primary, *args)
      end

      # Public: Find a single record by a key. Supports arguments
      # of the Hash or Ordered variety (see `find_by_primary_key`)
      #
      # key_name - Symbol name of the key.
      # args     - Hash or Ordered arguments.
      #
      # Examples
      #
      #     # Hash arguments
      #     User.find_by_key(:primary, :first_name => "John", :last_name => "Doe")
      #
      # Returns an Orel::Object or nil
      def find_by_key(key_name, *args)
        _finder.find_by_key(key_name, *args)
      end

      # Public: Retrieve objects with simple conditions.
      #
      # attributes - Hash of name/value pairs describing the values
      #              of objects to return.
      #
      # Examples
      #
      #     # Get all users with the last name 'Doe'
      #     User.find_all(:last_name => "Doe")
      #
      #     # Get all users with the first name 'John' and last name 'Doe'
      #     User.find_all(:first_name => "John", :last_name => "Doe")
      #
      # Returns an Array of Orel::Object.
      def find_all(*args)
        _finder.find_all(*args)
      end

      # Public: Retrieve objects with complex conditions.
      #
      # description - String description of the query for logging (default: none).
      #
      # Examples
      #
      #     # Get all users with the last name 'Doe'.
      #     User.query { |q, user|
      #       q.where user[:last_name].eq("Doe")
      #     }
      #
      #     # Get all users that have logged in from 127.0.0.1.
      #     User.query { |q, user|
      #       q.where user[:logins][:ip].eq("127.0.0.1")
      #     }
      #
      #     # Get all users and all of otheir logins.
      #     User.query { |q, user|
      #       q.join user[:logins]
      #     }
      #
      # Returns an Array of Orel::Object.
      def query(description=nil, &block)
        _query.query(description, &block)
      end

      def _finder
        @_finder ||= Orel::Finder.new(self, self.table, self.get_heading)
      end

      def _query
        @_query ||= Orel::Query.new(self)
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
      @simple_associations = SimpleAssociations.new(self, self.class.relation_set, self.class.connection)
      @operator = Operator.new(@heading, self.class.connection, @attributes)
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
      case
      when key.is_a?(Class) && key < Orel::Object
        @class_associations[key]
      when @simple_associations.include?(key)
        @simple_associations[key]
      else
        @attributes[key]
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
    # Returns a Boolean true if the save was successful.
    def save
      if valid?
        @operator.create_or_update
        @simple_associations.save
        true
      else
        false
      end
    end

    # Public: Persist the object's current attributes.
    #
    # Returns a Boolean true if the save was successful.
    # Raises Orel::Object::InvalidRecord if the save was NOT successful.
    def save!
      save or raise InvalidRecord.new(self, errors)
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

    # Public: Determine if this object is readonly. If it is, then no attributes
    # may be written or state persisted.
    #
    # Returns a Boolean.
    def readonly?
      @attributes.readonly && @operator.readonly
    end

    # Public: Determine if this object is locked for query. If it is, then
    # no associations may be used to retrieve data.
    #
    # Returns a Boolean.
    def locked_for_query?
      @class_associations.locked_for_query && @simple_associations.locked_for_query
    end

    def eql?(other)
      if other.is_a?(self.class)
        attributes.to_hash == other.attributes.to_hash
      else
        false
      end
    end

    alias_method :==, :eql?

    def hash
      attributes.to_hash.hash
    end

    def persisted!
      @operator.persisted = true
    end

    def readonly!
      @attributes.readonly = true
      @operator.readonly = true
    end

    def locked_for_query!
      @class_associations.locked_for_query = true
      @simple_associations.locked_for_query = true
    end

    # Used to store associated data found in a join query.
    def _store_association(association, data)
      raise "Cannot store when persisted" if persisted?
      case
      when association.is_a?(Class) && association < Orel::Object
        @class_associations._store(association, data)
      when @simple_associations.include?(association)
        @simple_associations._store(association, data)
      else
        raise ArgumentError, "Cannot store an assocation of type #{association.inspect}"
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

