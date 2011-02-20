module Orel
  module Relation

    ForeignKeyTranslationError = Class.new(StandardError)

    def self.extended(klass)
      Orel.classes << klass
    end

    def arel(sub_name=nil)
      Arel::Table.new(relation_name(sub_name))
    end

    def database
      @database ||= Database.new(self)
    end

    # Public: Get the name of this relation.
    #
    # sub_name - Symbol name of the sub-relation (default: get the base relation).
    #
    # Returns a String.
    def relation_name(sub_name=nil)
      database.relation_name(sub_name)
    end

    # Public: Get the heading of this relation.
    # sub_name - Symbol name of the sub-relation (default: get the base relation).
    #
    # Returns an Orel::Relation::Heading or nil.
    def get_heading(sub_name=nil)
      database.get_heading(sub_name)
    end

    # Top level DSL.

    def heading(sub_name=nil, &block)
      name = relation_name(sub_name)
      heading = Heading.new(name, sub_name.nil?)

      # Automatically add a foreign key to the base relation
      unless heading.base?
        local_heading = get_heading or raise "Missing base relation!"
        foreign_key = ForeignKey.create(local_heading, :primary, heading)
        # Add a key for the foreign key.
        heading.keys << foreign_key.local_key
        # Add the foreign key to the database.
        database.foreign_keys << foreign_key
      end

      # Execute the DSL.
      dsl = HeadingDSL.new(self, block)
      dsl._apply(heading, database)

      # Add the heading to the class's database.
      database.headings << heading
    end

    # Supporting classes

    # A database contains many relations, but we just
    # track the headings that define those relations.
    # We also maintain a set of relationships between
    # those relations in the form of foreign keys.
    class Database
      def initialize(klass)
        @klass = klass
        @headings = []
        @foreign_keys = []
      end
      attr_reader :klass
      attr_reader :headings
      attr_reader :foreign_keys
      def relation_name(sub_name=nil)
        [klass.name.underscore, sub_name].compact.join("_")
      end
      def get_heading(sub_name=nil)
        name = relation_name(sub_name)
        headings.find { |h| h.name == name }
      end
    end

    # A heading defines the attributes in a relation.
    # It includes 0 or more attributes and may also
    # group those attributes into keys. It may also
    # maintain a set of foreign keys that reference
    # other headings.
    class Heading
      def initialize(name, base)
        @name = name
        @base = base
        @attributes = []
        @keys = []
      end
      attr_reader :name
      attr_reader :base
      alias_method :base?, :base
      attr_reader :attributes
      attr_reader :keys
      def get_attribute(name)
        attributes.find { |a| a.name == name }
      end
      def get_key(name)
        keys.find { |k| k.name == name }
      end
    end

    # An attribute describes a field in a relation. It
    # has a name and is further defined by its domain.
    class Attribute
      def initialize(name, domain)
        @name = name
        @domain = domain
      end
      attr_reader :name
      attr_reader :domain
      def for_foreign_key_in(heading)
        unless domain.respond_to?(:for_foreign_key)
          raise ForeignKeyTranslationError, "#{domain.inspect} does not support foreign keys. It must define `for_foreign_key`."
        end
        # TODO: expose this naming assumption in a better way. It
        # should probably be an option to this method and be controller
        # by the DSL.
        if name == :id
          fk_name = [heading.name, name].join("_")
        else
          fk_name = name
        end
        fk_domain = domain.for_foreign_key
        self.class.new(fk_name, fk_domain)
      end
      def inspect
        "<Attribute #{name.inspect} #{domain.class}>"
      end
    end

    # A key is a set of 0 or more attributes that defines
    # a uniqueness constraint.
    class Key

      def initialize(name)
        @name = name
        @attributes = []
      end

      attr_reader :name
      attr_reader :attributes

      # Public: Convert this key into its foreign key equivalent.
      #
      # relation_name - String name of the
      #
      # Returns a new Orel::Relation::Key.
      def for_foreign_key_in(heading)
        fk_name = [heading.name, name].join("_")
        foreign_key = self.class.new(fk_name)
        attributes.each { |attribute|
          begin
            foreign_key.attributes << attribute.for_foreign_key_in(heading)
          rescue ForeignKeyTranslationError => e
            raise "Cannot convert key #{name} to a foreign key. #{e.message}"
          end
        }
        foreign_key
      end
    end

    class ForeignKey

      def self.create(local_heading, local_key_name, remote_heading)
        local_name = local_heading.name

        # Find the local key by name.
        local_key = local_heading.get_key(local_key_name) or raise "Missing key #{local_key_name.inspect } in #{local_name.inspect}"

        # Add all attributes in the local key to the remote heading.
        remote_heading.attributes.concat local_key.attributes.map { |a| a.for_foreign_key_in(local_heading) }

        # Convert the local heading's key into a key for the remote heading.
        remote_key = local_key.for_foreign_key_in(local_heading)

        # Create the foreign key.
        self.new(remote_heading, local_heading, remote_key, local_key)
      end

      def initialize(local_heading, foreign_heading, local_key, foreign_key)
        @local_heading = local_heading
        @foreign_heading = foreign_heading
        @local_key = local_key
        @foreign_key = foreign_key
      end
      attr_reader :local_heading
      attr_reader :foreign_heading
      attr_reader :local_key
      attr_reader :foreign_key
    end

    class Reference < Struct.new(:local_class, :key_name, :remote_class)
      def to_foreign_key
        local_heading = local_class.get_heading or raise "Missing heading for #{local_class}"
        remote_heading = remote_class.get_heading or raise "Missing heading for #{remote_class}"
        ForeignKey.create(local_heading, key_name, remote_heading)
      end
    end

    # This is the DSL that is used to build up a set of relations.
    class HeadingDSL
      def initialize(klass, block)
        @klass = klass
        @block = block
      end
      def key(name=:primary, &block)
        @keys[name] = KeyDSL.new(block)
      end
      def att(name, domain)
        attribute = Attribute.new(name, domain.new)
        @attributes << attribute
        attribute
      end
      def ref(klass)
        # TODO: allow references to non-primary keys
        @references << Reference.new(klass, :primary, @klass)
      end
      def _apply(heading, database)
        @attributes = []
        @references = []
        @keys = {}
        instance_eval(&@block)
        @attributes.each { |a| heading.attributes << a }
        @references.each { |ref| database.foreign_keys << ref }
        @keys.each { |name, dsl| dsl._apply(name, heading) }
      end
    end

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

      def initialize(block)
        @block = block
        @syntax = Syntaxes["/"]
      end
      def _apply(name, heading)
        # Get the source of the block as a string and split it into a series of identifiers.
        source = @block.to_source(:strip_enclosure => true)
        source.gsub!(@syntax[0], '')
        identifiers = source.split(@syntax[1])

        key = Key.new(name)
        identifiers.each { |identifier|
          case identifier
          when /^[A-Z]/
            # TODO: we'll need to support namespaced consts.
            klass = Object.const_get(identifier)
            # TODO: we might need to allow you to reference other keys.
            key_name = :primary

            klass_heading = klass.get_heading
            heading_key = klass_heading.get_key(key_name) or raise "Missing key #{key_name.inspect} in heading #{heading.inspect}"
            heading_key.attributes.each { |attribute|
              key.attributes << attribute.for_foreign_key_in(heading)
            }
          else
            attribute_name = identifier.to_sym
            attribute = heading.get_attribute(attribute_name) or raise "Missing attribute #{attribute_name.inspect} in heading #{heading.inspect}"
            # FIXME: why do we convert to foreign key in the Class case but not here?
            key.attributes << attribute #.for_foreign_key_in(heading.name)
          end
        }
        heading.keys << key
      end
    end

  end
end
