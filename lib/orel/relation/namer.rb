require 'digest/md5'

module Orel
  module Relation
    class Namer

      # The maximum string length of a mysql key.
      MYSQL_MAX_KEY_LENGTH = 64.freeze

      # Internal: Get a namer for a class. The options on the name
      # are determined by introspecting the class hierarchy.
      #
      # klass        - Class to name.
      # orel_options - Orel::Options that configure the naming.
      #
      # Returns an Orel::Relation::Namer.
      def self.for_class(klass, orel_options)
        options = {
          :prefix => orel_options.prefix,
          :suffix => orel_options.suffix,
          :pluralize => orel_options.pluralize
        }
        name = klass.name.split("::").last.underscore
        Namer.new(name, options)
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
        @name = name
        @options = options
        @pluralize = options[:pluralize]
        @prefix = options[:prefix]
        @suffix = options[:suffix]
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
      # Examples
      #
      #     namer = Namer.new("user")
      #     namer.foreign_attribute_name(:id)
      #     # => :user_id
      #
      #     namer = Namer.new("user")
      #     namer.foreign_attribute_name(:name)
      #     # => :name
      #
      # Returns a Symbol.
      def foreign_attribute_name(attribute_name)
        if attribute_name == :id
          [@name, attribute_name].join('_').to_sym
        else
          attribute_name
        end
      end

      # Internal: Transform a set of attribute names into the name of
      # a unique key constraint. The resulting name aims to be somewhat
      # visibly descriptive while also unique within an entire database.
      #
      # attribute_names - Array of Symbol names of the attributes in the key.
      #
      # Examples
      #
      #     namer = Namer.new("user")
      #     namer.unique_key_name([:first_name, :last_name])
      #     # => :u_fn_ln_[MD5("first_name::last_name")]
      #
      # Returns a Symbol.
      def unique_key_name(attribute_names)
        parts = [
          shorten(heading_name),
          attribute_names.map { |a| shorten(a) },
          Digest::MD5.hexdigest(attribute_names.join('::'))
        ]
        parts.flatten.join('_')[0, MYSQL_MAX_KEY_LENGTH].to_sym
      end

      def foreign_key_constraint_name(heading_name, attribute_names)
        parts = [
          shorten(self.heading_name),
          shorten(heading_name),
          attribute_names.map { |a| shorten(a) },
          Digest::MD5.hexdigest(attribute_names.join('::'))
        ]
        parts.flatten.join('_')[0, MYSQL_MAX_KEY_LENGTH].to_sym
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
