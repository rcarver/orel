module Orel
  class Attributes

    InvalidAttribute = Class.new(ArgumentError)
    InvalidReference = Class.new(ArgumentError)

    # Public: Initialize a new set of attributes.
    #
    # heading  - Orel::Releation::Heading that backs it.
    # defaults - Hash of key/value pairs to populate with.
    #
    def initialize(heading, defaults={})
      @heading = heading
      @attributes = {}
      defaults.each { |k, v| self[k] = v }
    end

    # Public: Determine if a key is in the heading.
    #
    # Returns a boolean.
    def att?(key)
      !! @heading.get_attribute(key.to_sym)
    end

    # Public: Get the current value of an attribute.
    #
    # key - Symbol attribute name.
    #
    # Returns most anything.
    def [](key)
      raise InvalidAttribute, "Attribute #{key.inspect} is not in #{@heading.name}" unless att?(key)
      @attributes[key.to_sym]
    end

    # Public: Set the value of an attribute or reference. If
    # you pass a Class, each attribute that is part of the
    # relationship will be set.
    #
    # key   - Symbol attribute name OR Class of a reference.
    # value - Whatever you want to set the value to.
    #
    # Examples
    #
    #     attrs = Attributes.new(heading)
    #     attrs[:name] = "John"
    #     attrs[:name]
    #     # => "John"
    #
    #     attrs = Attributes.new(heading)
    #     attrs[User] = User.new(:first_name => "John", :last_name => "Smith")
    #     attrs[:first_name]
    #     # => "John"
    #     attrs[:last_name]
    #     # => "Smith"
    #
    # Returns nothing.
    def []=(key, value)
      if key.is_a?(Orel::Relation)
        klass = key
        object = value
        raise ArgumentError, "Expected a #{klass} but got #{object.class}" unless object.is_a?(klass)

        reference = @heading.get_parent_reference(klass)
        raise InvalidReference, klass unless reference

        parent_key = reference.parent_key
        parent_heading = reference.parent_heading

        parent_key.attributes.each { |parent_attribute|
          child_attribute = parent_attribute.to_foreign_key
          self[child_attribute.name] = object.attributes[parent_attribute.name]
        }
      else
        raise InvalidAttribute, "Attribute #{key.inspect} is not in #{@heading.name}" unless att?(key)
        @attributes[key.to_sym] = value
      end
    end

    def hash
      @attributes.clone
    end

    def hash_excluding_keys(keys)
      output = {}
      @attributes.each { |k, v|
        output[k] = v unless keys.include?(k)
      }
      output
    end

    def extract_method_missing(message, args)
      if args.size == 1 && message.to_s =~ /^([^=]+)=$/
        key = $1.to_sym
        action = :set
      elsif args.size == 0
        key = message.to_sym
        action = :get
      end
      if key && att?(key)
        return key, action
      end
    end

    def inspect
      "<Attributes #{@attributes.inspect}>"
    end

  end
end
