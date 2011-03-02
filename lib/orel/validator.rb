module Orel
  class Validator

    def initialize(object, heading, attributes)
      @object = object
      @heading = heading
      @attributes = attributes
      @errors = new_errors
    end

    attr_reader :errors

    def valid?
      @errors = new_errors
      @heading.attributes.each { |attribute|
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
