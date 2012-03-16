module Orel
  module Relation
    # The set of relations belonging to a class.
    class Set

      def initialize(namer)
        @namer = namer
        @headings = []
      end

      include Enumerable

      def each(&block)
        @headings.each(&block)
      end

      def to_a
        @headings
      end

      def <<(heading)
        @headings << heading
      end

      def base
        name = @namer.heading_name
        @headings.find { |h| h.name == name }
      end

      def child(name)
        name = @namer.for_child(name).heading_name
        @headings.find { |h| h.name == name }
      end

    end
  end
end
