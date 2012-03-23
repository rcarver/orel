module Orel
  module Sharding
    # Decorates a Namer to add a suffix.
    class Namer

      def initialize(namer, suffix)
        @namer = namer
        @suffix = suffix
      end

      def table_name
        [@namer.table_name, "_", @suffix].join.to_sym
      end

      def method_missing(message, *args, &block)
        @namer.send(message, *args, &block)
      end
    end
  end
end
