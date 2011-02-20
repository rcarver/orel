module Orel
  class Attributes

    def initialize(heading, defaults={})
      @heading = heading
      @attributes = {}
      defaults.each { |k, v| self[k] = v }
    end

    def key?(key)
      !! @heading.get_attribute(key.to_sym)
    end

    def [](key)
      raise InvalidAttribute unless key?(key)
      @attributes[key.to_sym]
    end

    def []=(key, value)
      raise InvalidAttribute unless key?(key)
      @attributes[key.to_sym] = value
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
      if key && key?(key)
        return key, action
      end
    end

  end
end
