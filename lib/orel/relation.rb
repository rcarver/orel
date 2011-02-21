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

      # Execute the DSL.
      dsl = HeadingDSL.new(self, block)
      dsl._apply(database, sub_name)
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
        @references = []
        @keys = []
      end
      attr_reader :name
      attr_reader :base
      alias_method :base?, :base
      attr_reader :attributes
      attr_reader :references
      attr_reader :keys
      def get_attribute(name)
        attributes.find { |a| a.name == name }
      end
      def get_reference(klass)
        references.find { |r| r.child_class == klass }
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
      def foreign_key_for(heading)
        unless domain.respond_to?(:for_foreign_key)
          raise ForeignKeyTranslationError, "#{domain.inspect} does not support foreign keys. It must define `for_foreign_key`."
        end
        # TODO: expose this naming assumption in a better way. It
        # should probably be an option to this method and be controller
        # by the DSL.
        if name == :id
          fk_name = [heading.name, name].join("_").to_sym
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
      def foreign_key_for(heading)
        fk_name = [heading.name, name].join("_").to_sym
        foreign_key = self.class.new(fk_name)
        attributes.each { |attribute|
          begin
            foreign_key.attributes << attribute.foreign_key_for(heading)
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
        remote_heading.attributes.concat local_key.attributes.map { |a| a.foreign_key_for(local_heading) }

        # Convert the local heading's key into a key for the remote heading.
        remote_key = local_key.foreign_key_for(local_heading)

        # Create the foreign key.
        self.new(local_heading, local_key, remote_heading, remote_key)
      end

      def initialize(parent_heading, parent_key, child_heading, child_key)
        @parent_heading = parent_heading
        @parent_key = parent_key
        @child_heading = child_heading
        @child_key = child_key
      end
      attr_reader :parent_heading
      attr_reader :parent_key
      attr_reader :child_heading
      attr_reader :child_key
    end

    class ClassReference < Struct.new(:parent_class, :parent_heading_name, :child_class, :child_heading_name, :child_key_name)
      def parent_heading
        parent_class.get_heading(parent_heading_name)
      end
      def parent_key
        parent_heading.get_key(:primary)
      end
      def child_heading
        child_class.get_heading(child_heading_name)
      end
      def child_key
        child_heading.get_key(child_key_name)
      end
      def create_foreign_key_relationship
        child_heading.attributes.concat parent_key.attributes.map { |a|
          a.foreign_key_for(parent_heading)
        }
        child_key = parent_key.foreign_key_for(parent_heading)
        ForeignKey.new(parent_heading, parent_key, child_heading, child_key)
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
        @references << ClassReference.new(klass, nil, @klass, nil, :primary)
      end
      def _apply(database, sub_name)
        @attributes = []
        @references = []
        @keys = {}

        # Execute instructions.
        instance_eval(&@block)

        # Build the heading.
        name = database.relation_name(sub_name)
        heading = Heading.new(name, sub_name.nil?)

        # Automatically add a foreign key to the base relation
        unless heading.base?
          reference = ClassReference.new(@klass, nil, @klass, sub_name, :primary)

          parent_heading = reference.parent_heading
          parent_key = reference.parent_key
          child_key = parent_key.foreign_key_for(parent_heading)

          heading.keys << child_key
          heading.references << reference
        end

        # Apply results to the heading and database.
        @attributes.each { |a| heading.attributes << a }
        @references.each { |ref| heading.references << ref }
        @keys.each { |name, dsl| dsl._apply(name, heading) }

        # Add the heading to the database.
        database.headings << heading
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
              key.attributes << attribute.foreign_key_for(heading)
            }
          else
            attribute_name = identifier.to_sym
            attribute = heading.get_attribute(attribute_name) or raise "Missing attribute #{attribute_name.inspect} in heading #{heading.inspect}"
            # FIXME: why do we convert to foreign key in the Class case but not here?
            key.attributes << attribute #.foreign_key_for(heading.name)
          end
        }
        heading.keys << key
      end
    end

  end
end
