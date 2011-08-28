require 'digest/md5'

module Orel
  module Relation
    class Namer

      # The maximum length of a mysql key.
      MAX_MYSQL_KEY = 64.freeze

      def self.transformer(&block)
        @transformer = block
      end

      # Internal: Get a namer for a class. The options on the name
      # are determined by introspecting the class hierarchy.
      #
      # klass - Class to name.
      #
      # Returns an Orel::Relation::Namer.
      def self.for_class(klass)
        options = {
          :prefix => _find_prefix(klass),
          :suffix => _find_suffix(klass),
          :pluralize => true,
          :transformer => @transformer
        }
        name = klass.name.split("::").last.underscore
        Namer.new(name, options)
      end

      def self._find_prefix(klass)
        # parents is provided by ActiveSupport.
        parent = klass.parents.find { |p| p.respond_to?(:table_name_prefix) }
        parent.table_name_prefix if parent
      end

      def self._find_suffix(klass)
        # parents is provided by ActiveSupport.
        parent = klass.parents.find { |p| p.respond_to?(:table_name_suffix) }
        parent.table_name_suffix if parent
      end

      # Internal: Initialize a new namer.
      #
      # name    - String singular name.
      # options - Hash of options. All are required:
      #           :pluralize - Boolean true to pluralize `name` where appropriate.
      #           :prefix    - String to prefix to all names.
      #           :suffix    - String to append to all names.
      #
      def initialize(name, options)
        if options[:transformer] && (options[:prefix] || options[:suffix])
          raise ArgumentError, "transformer is deprecated and cannot be used along with prefix or suffix"
        end
        @name = name
        @options = options
        @pluralize = options[:pluralize]
        @transformer = options[:transformer]
        @prefix = options[:prefix]
        @suffix = options[:suffix]
        @name = @transformer.call(@name) if @transformer
      end

      # Internal: Get a new instance of Namer that creates names
      # for a child heading.
      #
      # Returns an Orel::Relation::Namer.
      def for_child(name)
        Namer.new([@name, name].join("_"), @options.merge(:pluralize => false))
      end

      # Internal: The name of the heading.
      #
      # Returns a Symbol.
      def heading_name
        if @pluralize
          ix(@name.pluralize).to_sym
        else
          ix(@name).to_sym
        end
      end

      # Internal: Transform an attribute name so it can be used
      # on the other side of a relationship.
      #
      # attribute_name - Symbol name of the attribute.
      #
      # Returns a Symbol.
      def foreign_attribute_name(attribute_name)
        if attribute_name == :id
          ix([@name, attribute_name].join('_')).to_sym
        else
          attribute_name
        end
      end

      # Internal: Transform a set of attribute names into the name of
      # a unique key constraint.
      #
      # attribute_names - Array of Symbol names of the attributes in the key.
      #
      # Returns a Symbol.
      def unique_key_name(attribute_names)
        parts = [
          shorten(heading_name),
          attribute_names.map { |a| shorten(a) },
          Digest::MD5.hexdigest(attribute_names.join('::'))
        ]
        parts.join('_')[0, MAX_MYSQL_KEY].to_sym
      end

      def foreign_key_constraint_name(this_name, other_name)
        [this_name, other_name, 'fk'].join('_').to_sym
      end

    protected

      def ix(name)
        [@prefix, name, @suffix].compact.join
      end

      def shorten(name)
        name.to_s.split('_').map { |part| part[0, 1] }.join
      end

    end
  end
end
