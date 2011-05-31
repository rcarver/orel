module Orel
  module Relation
    class Set

      def initialize(name, namer)
        @name = name
        @namer = namer
        @headings = []
      end

      include Enumerable

      def each(&block)
        @headings.each(&block)
      end

      def <<(heading)
        @headings << heading
      end

      def base
        @headings.find { |h| h.name == @name }
      end

      def child(name)
        name = @namer.child_name(name)
        @headings.find { |h| h.name == name }
      end

    end
  end
end
