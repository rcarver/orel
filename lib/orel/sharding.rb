module Orel
  module Sharding

    class TableSuffix
      def initialize(namer, suffix)
        @namer = namer
        @suffix = suffix
      end
      def table_name
        [@namer.table_name, "_", @suffix].join.to_sym
      end
      def method_missing(message, *args, &block)
        @namer.send(message, *args, &block)
      end
    end

    class ShardedTable
      def initialize(relation, attribute)
        @relation = relation
        @attribute = attribute
      end
      def insert(attributes)
        value = attributes[@attribute]
        table = @relation.shard(value)
        table.insert(attributes)
      end
      def query(&block)
        []
      end
    end

    def shard_table_on(attribute, &block)
      heading = get_heading
      @shard_attribute = attribute
      @shard_block = block
      @shard_namer = heading.namer.clone
      heading.namer = TableSuffix.new(heading.namer, "template")
    end

    def table(child_name=nil)
      if child_name
        super
      else
        ShardedTable.new(self, @shard_attribute)
      end
    end

    def shard(value)
      table = Table.new(shard_namer(value).table_name, get_heading, shard_connection(value))
      # TODO: we need to create the shard based on the actual template table to
      # account for indices and other table tweak that aren't captured by orel.
      create_shard(get_heading.with_namer(shard_namer(value)))
      #Sharding.create_table_from_template(heading.table_name, shard_heading.table_name)
      table
    end

    #
    # Internal
    #

    def shard_namer(value)
      instructions = @shard_block.call(value)
      case
      when instructions[:append_table_name]
        TableSuffix.new(@shard_namer, instructions[:append_table_name])
      else
        raise ArgumentError, "Unhandled shard instructions: #{instructions.inspect}"
      end
    end

    def shard_connection(value)
      connection
    end

    def shard_schema_connection(value)
      connection
    end

    def create_shard(heading)
      begin
        Orel::SchemaGenerator.creation_statements([heading]).each { |statement|
          shard_schema_connection(heading).execute(statement)
        }
      rescue ActiveRecord::StatementInvalid => e
        raise unless e.message =~ /already exists/
      end
    end

    #def self.create_table_from_template(template_name, table_name)
      #access = MysqlInspector::AR::Access.new(schema_connection)
      #tables = access.tables
      #table = tables.find { |t| t.name.to_s == table_name.to_s }
      #template = tables.find { |t| t.name.to_s == template_name.to_s }
      #if !table
        #table = MysqlInspector::Table.new(template.to_sql)
        #table.name = table_name
        #access.load(table.to_sql)
      #end
    #end

  end
end
