module Orel
  module Relation
    class Namer

      def initialize(klass)
        @klass = klass
        @name = @klass.name.underscore.gsub(/\//, '_')
      end

      def base_name
        @name.pluralize
      end

      def child_name(name)
        [@name, name.to_s.pluralize].join("_")
      end

    end
  end
end
