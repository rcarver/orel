module Orel
  class Operator

    def initialize(heading, attributes)
      @heading = heading
      @attributes = attributes
      @table = Orel::Sql::Table.new(@heading)
      @persisted = false
    end

    attr_reader :persisted
    alias_method :persisted?, :persisted

    def has_heading_attribute?(name)
      !! @heading.get_attribute(name)
    end

    def create
      serial = get_serial_key_attribute
      keys = serial ? [serial.name] : []
      attributes_to_insert = remove_hash_keys(@attributes, keys)
      statement = @table.insert_statement(attributes_to_insert)

      auto_id = Orel.insert(statement)

      if serial
        @attributes[serial.name] = auto_id
      end

      @persisted = true
    end

    def update
      attributes_for_key = Hash[get_primary_key.attributes.map { |a| [a.name, @attributes[a.name]] }]
      attributes_to_update = remove_hash_keys(@attributes, attributes_for_key.keys)

      # TODO: since we're not updating attributes in the primary key,
      # it's possible to have nothing to update. That's weird, right?
      unless attributes_to_update.empty?
        statement = @table.update_statement(attributes_to_update, attributes_for_key)

        Orel.execute(statement)
      end
    end

    def destroy
      attributes_for_key = Hash[get_primary_key.attributes.map { |a| [a.name, @attributes[a.name]] }]
      statement = @table.delete_statement(attributes_for_key)

      Orel.execute(statement)
    end

  protected

    def get_primary_key
      @heading.get_key(:primary)
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

