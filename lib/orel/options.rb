module Orel
  class Options

    def initialize(klass)
      @options = find_options(klass)
    end

    attr_reader :options

    def prefix
      @options.fetch(:prefix, nil)
    end

    def suffix
      @options.fetch(:suffix, nil)
    end

    def pluralize
      @options.fetch(:pluralize, true)
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
          options.update(:prefix => k.table_name_prefix)
        end
        if k.respond_to?(:table_name_suffix)
          options.update(:suffix => k.table_name_suffix)
        end
      }
      options
    end

  end
end
