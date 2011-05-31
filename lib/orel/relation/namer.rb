module Orel
  module Relation
    class Namer

      def initialize(klass)
        @klass = klass
      end

      def base_name
        @klass.name.underscore.gsub(/\//, '_')
      end

      def child_name(name)
        [base_name, name.to_s].join("_")
      end

    end
  end
end
