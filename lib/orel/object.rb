module Orel
  module Object

    def self.included(base)
      base.extend Orel::Relation
    end

    def initialize(attributes={})
      @attributes = Hash[attributes.map { |k, v| [k.to_sym, v] }]
    end

    def method_missing(message, *args, &block)
      case message.to_s
      when /^([^=]+)=$/
        key = $1.to_sym
        # TODO: should only be one arg
        @attributes[key] = args.first
        return args.first
      else
        key = message.to_sym
        return @attributes[key] if @attributes.key?(key)
      end
      super
    end

  end
end

