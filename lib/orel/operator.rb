module Orel
  class Operator

    def initialize(heading, attributes)
      @heading = heading
      @attributes = attributes
      @table = Orel::Sql::Table.new(@heading)
      @persisted = false
      @destroyed = false
    end

    attr_reader :persisted
    alias_method :persisted?, :persisted

    attr_reader :destroyed
    alias_method :destroyed?, :destroyed

    def has_heading_attribute?(name)
      !! @heading.get_attribute(name)
    end

    def create
      serial = get_serial_key_attribute
      keys = serial ? [serial.name] : []

      attributes_to_insert = @attributes.hash_excluding_keys(keys)
      statement = @table.insert_statement(attributes_to_insert)

      begin
        auto_id = Orel.insert(statement)

        if serial
          @attributes[serial.name] = auto_id
        end

        @persisted = true
      rescue StandardError => e
        debug_sql_error(statement)
        raise
      end
    end

    def update
      attributes_for_key = hash_of_primary_key

      if serial = get_serial_key_attribute
        attributes_to_update = @attributes.hash_excluding_keys([serial.name])
      else
        attributes_to_update = @attributes.hash
      end

      # TODO: since we're not updating attributes in the primary key,
      # it's possible to have nothing to update. That's weird, right?
      unless attributes_to_update.empty?
        statement = @table.update_statement(attributes_to_update, attributes_for_key)

        begin
          Orel.execute(statement)
        rescue StandardError => e
          debug_sql_error(statement)
          raise
        end
      end
    end

    def destroy
      attributes_for_key = hash_of_primary_key
      statement = @table.delete_statement(attributes_for_key)

      begin
        Orel.execute(statement)

        @destroyed = true
      rescue StandardError => e
        debug_sql_error(statement)
        raise
      end
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

    def hash_of_primary_key
      pairs = get_primary_key.attributes.map { |a|
        key = a.name
        value = @attributes.changed_attributes[a.name] || @attributes[a.name]
        [key, value]
      }
      Hash[pairs]
    end

    def debug_sql_error(statement)
      Orel.logger.fatal "A SQL error occurred while executing:\n#{statement}"
    end

  end
end

