module Orel
  module Relation
    class KeyDSL

      # Experimenting with various syntaxes. The ideal
      # delimiter is a comma but that's basically the
      # only thing that causes syntax errors.
      #
      # key { User | name }
      # key { User / name }
      #
      Syntaxes = {
        # clean, split
        "|" => [/\.|\(|\)/, /\s*\|\s*/],
        "/" => [/\(|\)/, /\s*\/\s*/]
      }

      def initialize(name, heading, &block)
        @name = name
        @heading = heading
        @block = block
        @syntax = Syntaxes["/"]
      end

      def _apply!
        # Get the source of the block as a string and split it into a series of identifiers.
        source = @block.to_source(:strip_enclosure => true)
        source.gsub!(@syntax[0], '')
        identifiers = source.split(@syntax[1])

        key = Key.new(@name)
        identifiers.each { |identifier|
          case identifier
          when /^[A-Z]/
            # Constantize a string.
            klass = identifier.split("::").inject(Object) { |o, i| o.const_get(i) }

            klass_heading = klass.get_heading
            references = @heading.references.find_all { |r| r.parent_class == klass }

            raise ArgumentError, "Heading #{@heading.name} has no reference to #{klass}" if references.empty?
            raise ArgumentError, "Heading #{@heading.name} has multiple references to #{klass}" if references.size > 1

            heading_key = references.first.parent_key
            heading_key.attributes.each { |attribute|
              key.attributes << attribute.to_foreign_key
            }
          else
            attribute_name = identifier.to_sym
            attribute = @heading.get_attribute(attribute_name) or raise "Missing attribute #{attribute_name.inspect} in heading #{@heading.inspect}"
            # FIXME: why do we convert to foreign key in the Class case but not here?
            key.attributes << attribute #.foreign_key_for(@heading.name)
          end
        }
        @heading.keys << key
      end

    end
  end
end


