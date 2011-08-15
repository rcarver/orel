module Orel
  # This class performs SQL operations using a heading and attributes.
  # The heading describes the table to operate on and the attributes
  # describe the current values. With that information we can do  basic
  # ORM CRUD operations on behalf of Orel objects.
  class Operator

    # Internal: Create a new Operator
    #
    # heading    - Orel::Relation::Heading that describes the table.
    # attributes - Orel::Attributes used to manipulate that heading.
    #
    def initialize(heading, attributes)
      @heading = heading
      @attributes = attributes
      @table = Orel::Table.new(heading)
      @persisted = false
      @destroyed = false
      @readonly = false
    end

    attr_accessor :readonly

    # Internal: Determine if our attributes have been stored in the heading.
    attr_accessor :persisted
    alias_method  :persisted?, :persisted

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
      raise Orel::ReadonlyError if @readonly

      serial = get_serial_key_attribute
      keys = serial ? [serial.name] : []

      attributes_to_insert = @attributes.hash_excluding_keys(keys)

      auto_id = @table.insert(attributes_to_insert)
      if serial
        @attributes[serial.name] = auto_id
      end
      @persisted = true
    end

    # Internal: Update the non-key values of my attributes in the relation
    # described by my heading.
    #
    # Returns nothing.
    # Raises errors if something goes wrong while executing sql.
    def update
      raise Orel::ReadonlyError if @readonly

      attributes_for_key = hash_of_current_primary_key

      if serial = get_serial_key_attribute
        attributes_to_update = @attributes.hash_excluding_keys([serial.name])
      else
        attributes_to_update = @attributes.to_hash
      end

      # TODO: since we're not updating attributes in the primary key,
      # it's possible to have nothing to update. That's weird, right?
      unless attributes_to_update.empty?
        @table.update(
          :find => attributes_for_key,
          :set  => attributes_to_update
        )
      end
    end

    # Internal: Remove my attributes from the relation described by my heading.
    #
    # Returns nothing.
    # Raises errors if something goes wrong while executing sql.
    def destroy
      raise Orel::ReadonlyError if readonly?

      attributes_for_key = hash_of_current_primary_key

      @table.delete(attributes_for_key)
      @destroyed = true
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

