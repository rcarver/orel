module Orel
  # Provides ActiveModel compatible validation.
  class Validator

    # Initialize a new validator.
    #
    # object     - Orel::Object to validate.
    # heading    - Orel::Relation::Heading to validate.
    # attributes - Orel::Attributes containing the values to validate.
    #
    def initialize(object, heading, attributes)
      @object = object
      @heading = heading
      @attributes = attributes
      @errors = new_errors
    end

    # Public: Get the current errors.
    #
    # Returns an instance of ActiveModel::Errors.
    attr_reader :errors

    # Public: Validate the attributes against the heading. Calling this
    # method will populate the `errors` object with more information
    # about why an attribute is invalid.
    #
    # Returns a boolean true if all attributes are valid.
    def valid?
      @errors = new_errors
      @heading.attributes.each { |attribute|
        unless @object.persisted?
          next if attribute.domain.is_a?(Orel::Domains::Serial)
        end

        # TODO: implement domain specific validations
        value = @attributes[attribute.name]
        if value.nil?
          @errors.add(attribute.name, "cannot be blank")
        end
      }
      @errors.size == 0
    end

  protected

    def new_errors
      ActiveModel::Errors.new(@object)
    end

  end
end
