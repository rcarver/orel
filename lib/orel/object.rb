module Orel
  module Object

    def self.included(base)
      base.extend Orel::Relation
    end

    def initialize(attributes={})
      @attributes = Hash[attributes.map { |k, v| [k.to_sym, v] }]
      @_orel_persisted = false
    end

    def id
      if has_attribute?(:id)
        @attributes[:id]
      else
        super
      end
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

    def save
      if @_orel_persisted
        update
      else
        create
      end
    end

    def destroy
      heading = self.class.get_heading
      table = Orel::Sql::Table.new(heading)

      attributes_for_key = Hash[get_primary_key.attributes.map { |a| [a.name, @attributes[a.name]] }]
      statement = table.delete_statement(attributes_for_key)

      Orel.execute(statement)
    end

  protected

    def create
      heading = self.class.get_heading
      table = Orel::Sql::Table.new(heading)

      serial = get_serial_key_attribute
      keys = serial ? [serial.name] : []
      attributes_to_insert = remove_hash_keys(@attributes, keys)
      statement = table.insert_statement(attributes_to_insert)

      auto_id = Orel.insert(statement)

      if serial
        @attributes[serial.name] = auto_id
      end

      @_orel_persisted = true
    end

    def update
      heading = self.class.get_heading
      table = Orel::Sql::Table.new(heading)

      attributes_for_key = Hash[get_primary_key.attributes.map { |a| [a.name, @attributes[a.name]] }]
      attributes_to_update = remove_hash_keys(@attributes, attributes_for_key.keys)

      # TODO: since we're not updating attributes in the primary key,
      # it's possible to have nothing to update. That's weird, right?
      unless attributes_to_update.empty?
        statement = table.update_statement(attributes_to_update, attributes_for_key)

        Orel.execute(statement)
      end
    end

    def has_attribute?(name)
      !! self.class.get_heading.get_attribute(name)
    end

    def get_primary_key
      heading = self.class.get_heading
      heading.get_key(:primary)
    end

    def get_serial_key_attribute
      if key = get_primary_key
        key.attributes.find { |a| a.domain.is_a? Orel::Domains::Serial }
      end
    end

    def remove_hash_keys(hash, keys)
      output = {}
      hash.each { |k, v|
        output[k] = v unless keys.include?(k)
      }
      output
    end

  end
end

