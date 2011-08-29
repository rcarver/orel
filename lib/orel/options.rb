module Orel
  class Options

    def initialize(klass)
      @options = find_options(klass)
    end

    attr_reader :options

    def relation_prefix
      @options.fetch(:relation_prefix, nil)
    end

    def relation_suffix
      @options.fetch(:relation_suffix, nil)
    end

    def attribute_prefix
      @options.fetch(:attribute_prefix, nil)
    end

    def pluralize_relations
      @options.fetch(:pluralize_relations, true)
    end

    def active_record
      @options.fetch(:active_record, Orel::AR)
    end

  protected

    def find_options(klass)
      options = {}
      # klass.parents is provided by ActiveSupport.
      hierarchy = ([klass] + klass.parents).reverse
      hierarchy.each { |k|
        if k.respond_to?(:orel_options)
          options.update(k.orel_options)
        end
        if k.respond_to?(:table_name_prefix)
          options.update(:relation_prefix => k.table_name_prefix)
        end
        if k.respond_to?(:table_name_suffix)
          options.update(:relation_suffix => k.table_name_suffix)
        end
      }
      options
    end

  end
end
