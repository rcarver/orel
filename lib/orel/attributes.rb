module Orel
  class Attributes

    InvalidAttribute = Class.new(ArgumentError)
    InvalidReference = Class.new(ArgumentError)

    def initialize(heading, defaults={})
      @heading = heading
      @attributes = {}
      defaults.each { |k, v| self[k] = v }
    end

    def att?(key)
      !! @heading.get_attribute(key.to_sym)
    end

    def [](key)
      raise InvalidAttribute, key unless att?(key)
      @attributes[key.to_sym]
    end

    def []=(key, value)
      if key.is_a?(Orel::Relation)
        klass = key
        object = value
        raise ArgumentError, "Expected a #{klass} but got #{object.class}" unless object.is_a?(klass)

        reference = @heading.get_reference(klass)
        raise InvalidReference, klass unless reference

        key = reference.child_key
        heading = reference.child_heading

        key.attributes.each { |a|
          rename = a.for_foreign_key_in(heading)
          self[rename.name] = object.attributes[a.name]
        }
      else
        raise InvalidAttribute, key unless att?(key)
        @attributes[key.to_sym] = value
      end
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
