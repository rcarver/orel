module Orel
  # This class performs SQL operations using a heading and attributes.
  # The heading describes the table to operate on and the attributes
  # describe the current values. With that information we can do  basic
  # ORM CRUD operations on behalf of Orel objects.
  class Operator
    include Orel::SqlDebugging

    # Internal: Create a new Operator
    #
    # heading    - Orel::Relation::Heading to manipulate.
    # attributes - Orel::Attributes used to manipulate that heading.
    #
    def initialize(heading, attributes)
      @heading = heading
      @attributes = attributes
      @table = Orel::Sql::Table.new(@heading)
      @persisted = false
      @destroyed = false
    end

    # Internal: Determine if our attributes have been stored in the heading.
    attr_reader :persisted
    alias_method :persisted?, :persisted

    # Internal: Determine if our attributes have been removed from the heading.
    attr_reader :destroyed
    alias_method :destroyed?, :destroyed

    def create_or_update
      if persisted?
        update
      else
        create
      end
    end

    # Internal: Store my attributes in the relation described by my heading.
    #
    # Returns nothing.
    # Raises errors if something goes wrong while executing sql.
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

    # Internal: Update the non-key values of my attributes in the relation
    # described by my heading.
    #
    # Returns nothing.
    # Raises errors if something goes wrong while executing sql.
    def update
      attributes_for_key = hash_of_current_primary_key

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

    # Internal: Remove my attributes from the relation described by my heading.
    #
    # Returns nothing.
    # Raises errors if something goes wrong while executing sql.
    def destroy
      attributes_for_key = hash_of_current_primary_key
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
      @heading.get_key(:primary) or raise "#{@heading.name} has no :primary key. #{@heading.inspect}"
    end

    def get_serial_key_attribute
      if key = get_primary_key
        key.attributes.find { |a| a.domain.is_a? Orel::Domains::Serial }
      end
    end

    def hash_of_current_primary_key
      pairs = get_primary_key.attributes.map { |a|
        key = a.name
        value = @attributes.changed_attributes[a.name] || @attributes[a.name]
        [key, value]
      }
      Hash[pairs]
    end

  end
end

