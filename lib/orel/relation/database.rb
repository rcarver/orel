module Orel
  module Relation
    # This database describes zero or more headings
    # that are created as part of a class.
    class Database

      def initialize(klass)
        @klass = klass
        @headings = []
      end

      attr_reader :klass
      attr_reader :headings

      def relation_name(sub_name=nil)
        [klass.name.underscore, sub_name].compact.join("_")
      end

      def get_heading(sub_name=nil)
        name = relation_name(sub_name)
        headings.find { |h| h.name == name }
      end

    end
  end
end
