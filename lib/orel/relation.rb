module Orel
  module Relation

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
      tables = orel.headings.map { |name, heading| Orel::Sql::Table.new(name, heading) }
      Orel::Sql::Database.new(tables)
    end

    def relation_name(sub_name=nil)
      [self.name.underscore, sub_name].compact.join("_")
    end

    def heading(sub_name=nil, &block)
      heading = Heading.new
      HeadingDSL.new(heading, block)
      orel.headings[relation_name(sub_name)] = heading
    end

    # Supporting classes

    # A database contains many relations, but we just
    # track the headings that define those relations.
    class Database
      def initialize
        @headings = {}
      end
      attr_reader :headings
    end

    # A heading defines the attributes in a relation.
    # It includes 0 or more attributes and may also 
    # group those attributes into keys.
    class Heading
      def initialize
        @attributes = []
        @keys = []
      end
      attr_reader :attributes
      attr_reader :keys
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
