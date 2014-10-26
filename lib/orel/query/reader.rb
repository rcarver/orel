module Orel
  class Query
    class Reader

      def initialize(klass, heading, connection, query, select_manager, description)
        @klass = klass
        @heading = heading
        @connection = connection
        @query = query
        @select_manager = select_manager
        @description = description
      end

      def read_all
        read @description || "#{Orel::Query} on #{@klass}"
      end

      def read_batch(start, count)
        @select_manager.take count
        @select_manager.skip start
        batch_desc = "(batch rows: #{start}-#{start + count})"
        read @description ? "#{@description} #{batch_desc}" : "#{Orel::Query} #{batch_desc} on #{@klass}"
      end

    protected

      def read(description)
        # Execute the query.
        rows = @connection.execute(@select_manager.to_sql, description)

        # Extract objects from rows.
        if @query.projected_joins.empty?
          objects = extract_objects_without_joins(rows)
        else
          objects = extract_objects_with_joins(@query.projected_joins, rows)
        end

        # Finalize and return the objects.
        objects.each { |object|
          # The object is persisited because it came from the databse.
          object.persisted!

          # The object is readonly because it's a complex relation
          object.readonly!

          # The object is locked for query because you should get all
          # of the data you're interested in one shot.
          object.locked_for_query! if @query.locked_for_query
        }
      end

      def extract_objects_without_joins(rows)
        rows.each(:as => :hash).map { |row|
          @klass.new(row)
        }
      end

      def extract_objects_with_joins(projected_joins, rows)
        objects = []
        objects_hash = {}
        rows.each(:as => :hash) { |row|

          # Extract association projections from the row.
          association_projections = {}
          projected_joins.each { |join|
            join_id = join.join_id
            association_projections[join.join_class] = {}
            row.each { |key, value|
              if key[0, join_id.size] == join_id
                name = key[(join_id.size)..-1]
                row.delete(key)
                association_projections[join.join_class][name] = value
              end
            }
          }

          # Only instantiate the object once.
          if objects_hash[row]
            object = objects_hash[row]
          else
            object = objects_hash[row] = @klass.new(row)
            objects << object
          end

          projected_joins.each { |join|
            object._store_association(join.join_class, association_projections[join.join_class])
          }
        }
        objects
      end
    end
  end
end
