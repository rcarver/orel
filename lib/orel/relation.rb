module Orel
  module Relation

    ForeignKeyTranslationError = Class.new(StandardError)

    def self.extended(klass)
      Orel.classes << klass
    end

    def arel(sub_name=nil)
      Arel::Table.new(relation_name(sub_name))
    end

    def orel
      @orel ||= Database.new
    end

    def sql
      tables = orel.headings.map { |heading|
        Orel::Sql::Table.new(heading)
      }
      foreign_keys = orel.foreign_keys.map { |foreign_key|
        local_table = Orel::Sql::Table.new(foreign_key.local_heading)
        foreign_table = Orel::Sql::Table.new(foreign_key.foreign_heading)
        local_attributes = foreign_key.local_key.attributes
        foreign_attributes = foreign_key.foreign_key.attributes
        Orel::Sql::ForeignKey.new(local_table.name, foreign_table.name, local_attributes, foreign_attributes)
      }
      Orel::Sql::Database.new(tables, foreign_keys)
    end

    def relation_name(sub_name=nil)
      [self.name.underscore, sub_name].compact.join("_")
    end

    def heading(sub_name=nil, &block)
      name = relation_name(sub_name)
      heading = Heading.new(name, sub_name.nil?)
      unless heading.base?
        base_name = relation_name
        # Find the base heading.
        base_heading = orel.headings.find { |h| h.name == base_name } or raise "Missing base relation #{base_name}"
        # Find the base heading's primary key.
        base_key = base_heading.keys.find { |k| k.name == :primary } or raise "Missing primary key in #{base_name}"
        # Add attributes used in the base table's key to the new heading.
        heading.attributes.concat base_key.attributes.map { |a| a.for_foreign_key(base_name) }
        # Convert the base heading's key into a key for the new heading.
        foreign_key = base_key.for_foreign_key(base_name)
        heading.keys << foreign_key
        # Add a foreign key to the database to link these two headings.
        orel.foreign_keys << ForeignKey.new(heading, base_heading, foreign_key, base_key)
      end
      HeadingDSL.new(heading, block)
      orel.headings << heading
    end

    # Supporting classes

    # A database contains many relations, but we just
    # track the headings that define those relations.
    # We also maintain a set of relationships between
    # those relations in the form of foreign keys.
    class Database
      def initialize
        @headings = []
        @foreign_keys = []
      end
      attr_reader :headings
      attr_reader :foreign_keys
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
        @foreign_keys = []
      end
      attr_reader :name
      attr_reader :base
      alias_method :base?, :base
      attr_reader :attributes
      attr_reader :keys
      attr_reader :foreign_keys
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
      def for_foreign_key(relation_name)
        unless domain.respond_to?(:for_foreign_key)
          raise ForeignKeyTranslationError, "#{domain.inspect} does not support foreign keys. It must define `for_forign_key`."
        end
        fk_name = [relation_name, name].join("_")
        fk_domain = domain.for_foreign_key
        self.class.new(fk_name, fk_domain)
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
      def for_foreign_key(relation_name)
        fk_name = [relation_name, name].join("_")
        foreign_key = self.class.new(fk_name)
        attributes.each { |attribute|
          begin
            foreign_key.attributes << attribute.for_foreign_key(relation_name)
          rescue ForeignKeyTranslationError => e
            raise "Cannot convert key #{name} to a foreign key. #{e.message}"
          end
        }
        foreign_key
      end
    end

    class ForeignKey
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

    # This is the DSL that is used to build up a set of relations.
    class HeadingDSL
      def initialize(heading, block)
        @attributes = []
        @keys = {}
        instance_eval(&block)
        @attributes.each { |a| heading.attributes << a }
        @keys.values.each { |k| heading.keys << k }
      end
      def key(name, domain)
        @keys[:primary] ||= Key.new(:primary)
        @keys[:primary].attributes << att(name, domain)
      end
      def att(name, domain)
        attribute = Attribute.new(name, domain.new)
        @attributes << attribute
        attribute
      end
    end

  end
end
