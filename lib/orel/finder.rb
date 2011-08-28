module Orel
  # Retrieve instances of Orel::Object that have been persisted.
  class Finder

    # Internal: Initialize a finder.
    #
    # klass   - Class that methods will return.
    # table   - Orel::Table containing data.
    # heading - Orel::Relation::Heading describing the relation.
    #
    def initialize(klass, table, heading)
      @klass = klass
      @table = table
      @heading = heading
    end

    # Internal: Look for a record using a key.
    #
    # key_name - Symbol name of the key.
    # args     - Hash or Array of args.
    #
    # Returns an Orel::Object or nil.
    def find_by_key(key_name, *args)
      key = @heading.get_key(key_name) or raise ArgumentError, "Key #{key_name.inspect} does not exist"

      if args.first.is_a?(Hash)
        raise ArgumentError, "Extraneous args to #find_by_key: #{args.inspect}" if args.size > 1
        attrs = args.first
        attr_names = attrs.keys
        key_names = key.attributes.map { |a| a.name }
        raise ArgumentError, "Find attributes do not match key attributes (find: #{attr_names.inspect}, key: #{key_names.inspect}" if Set.new(key_names) != Set.new(attrs.keys)
      else
        raise ArgumentError, "The number of arguments does not match the number of attributes in key #{key_name.inspect}" if key.attributes.size != args.size
        attrs = Hash[*key.attributes.map { |a| a.name }.zip(args).flatten]
      end

      results = find_all(attrs)
      results.empty? ? nil : results.first
    end

    # Internal: Look for all records with some attribute(s).
    #
    # attrs - Hash of key/value pairs describing the attributes.
    #
    # Returns an Array of Orel::Object.
    def find_all(attrs)
      results = @table.query { |q, table|
        @heading.attributes.each { |a|
          q.project table[a.name]
        }
        attrs.each { |k, v|
          q.where table[k].eq(v)
        }
      }

      if results.empty?
        []
      else
        results.map { |result|
          object = @klass.new(result)
          object.persisted!
          object
        }
      end
    end

  end
end
