module Orel
  class Translator

    def self.create_tables!(classes)
      translator = new(*classes)
      database = translator.database
      database.create_tables!
    end

    def initialize(*classes)
      @classes = classes
    end

    def database
      tables = @classes.map { |klass|
        klass.database.headings.map { |heading|
          Orel::Sql::Table.new(heading)
        }
      }

      foreign_keys = @classes.map { |klass|
        klass.database.foreign_keys.map { |foreign_key|
          case foreign_key
          when Orel::Relation::Reference
            foreign_key = foreign_key.to_foreign_key
          else
            foreign_key = foreign_key
          end
          local_table = Orel::Sql::Table.new(foreign_key.local_heading)
          foreign_table = Orel::Sql::Table.new(foreign_key.foreign_heading)
          local_attributes = foreign_key.local_key.attributes
          foreign_attributes = foreign_key.foreign_key.attributes
          Orel::Sql::ForeignKey.new(local_table.name, foreign_table.name, local_attributes, foreign_attributes)
        }
      }

      Orel::Sql::Database.new(tables.flatten, foreign_keys.flatten)
    end

  end
end
