require 'digest/md5'

module Orel
  module Relation
    class Namer

      def self.transformer(&block)
        @transformer = block
      end

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

      def initialize(name, options={})
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

      def for_child(name)
        Namer.new([@name, name].join("_"), @options.merge(:pluralize => false))
      end

      def heading_name
        if @pluralize
          ix(@name.pluralize).to_sym
        else
          ix(@name).to_sym
        end
      end

      # Used in Attribute.
      def foreign_key_name(attribute_name)
        if attribute_name == :id
          fk_name = ix([@name, attribute_name].join('_')).to_sym
        else
          attribute_name
        end
      end

      # Used to generate sql
      def unique_key_name(attribute_names)
        short_names = attribute_names.map do |a|
          a.to_s.split('_').map do |part|
            part[0,1]
          end.join
        end
        full_name = [ix(@name).split('_').map { |part| part[0,1] }.join, short_names, Digest::MD5.hexdigest(attribute_names.join('::'))].join('_')
        full_name[0,64].to_sym
      end

      # Used to generate sql
      def foreign_key_constraint_name(this_name, other_name)
        [this_name, other_name, 'fk'].join('_').to_sym
      end

    protected

      def ix(name)
        [@prefix, name, @suffix].compact.join
      end

    end
  end
end
