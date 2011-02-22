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
            # TODO: we'll need to support namespaced consts.
            klass = Object.const_get(identifier)
            # TODO: we might need to allow you to reference other keys.
            key_name = :primary

            klass_heading = klass.get_heading
            heading_key = klass_heading.get_key(key_name) or raise "Missing key #{key_name.inspect} in heading #{@heading.inspect}"
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


