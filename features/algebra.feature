@algebra
Feature: Perform relational algebra

  Scenario: Perform a projection
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      Orel.execute "INSERT INTO users (first_name, last_name) VALUES ('John', 'Smith')"
      Orel.execute "INSERT INTO users (first_name, last_name) VALUES ('Mary', 'Smith')"

      algebra = Orel::Algebra.new(User)
      algebra.project
      puts algebra.to_sql

      Orel::Test.wrap_and_sort {
        algebra.each { |tuple|
          puts [tuple[:first_name], tuple[:last_name]].join(",")
        }
      }
      """
    Then the output should contain:
      """
      SELECT * FROM `users` 
      ---
      John,Smith
      Mary,Smith
      ---
      """

  Scenario: Perform a restriction
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      Orel.execute "INSERT INTO users (first_name, last_name) VALUES ('John', 'Smith')"
      Orel.execute "INSERT INTO users (first_name, last_name) VALUES ('Mary', 'Smith')"

      algebra = Orel::Algebra.new(User)
      algebra.restrict(:first_name => "John")
      algebra.project
      puts algebra.to_sql

      Orel::Test.wrap_and_sort {
        algebra.each { |tuple|
          puts [tuple[:first_name], tuple[:last_name]].join(",")
        }
      }
      """
    Then the output should contain:
      """
      SELECT * FROM `users`  WHERE `users`.`first_name` = 'John'
      ---
      John,Smith
      ---
      """

  Scenario: Perform an inner join
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      class Thing
        extend Orel::Relation
        heading do
          key { User / name }
          ref User
          att :name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      Orel.execute "INSERT INTO users (first_name, last_name) VALUES ('John', 'Smith')"
      Orel.execute "INSERT INTO users (first_name, last_name) VALUES ('Mary', 'Smith')"
      Orel.execute "INSERT INTO things (first_name, last_name, name) VALUES ('John', 'Smith', 'Car')"
      Orel.execute "INSERT INTO things (first_name, last_name, name) VALUES ('John', 'Smith', 'Boat')"
      Orel.execute "INSERT INTO things (first_name, last_name, name) VALUES ('Mary', 'Smith', 'Boat')"

      algebra = Orel::Algebra.new(User)
      algebra.join(Thing)
      algebra.project
      puts algebra.to_sql

      Orel::Test.wrap_and_sort {
        algebra.each { |tuple|
          puts [tuple[:first_name], tuple[:last_name], tuple[:name]].join(",")
        }
      }
      """
    Then the output should contain:
      """
      SELECT * FROM `users` INNER JOIN `things` ON `things`.`first_name` = `users`.`first_name` AND `things`.`last_name` = `users`.`last_name`
      ---
      John,Smith,Boat
      John,Smith,Car
      Mary,Smith,Boat
      ---
      """

  #class Agreement

    ## primitive relational operators (did.93)

    #restrict :expensive do |price|
      #agreements.where(agreements[:base_cost]).gt(price.cents)
    #end

    #project :everything do
      #agreements.project(Arel.sql('*'))
    #end

    #join :entities do
      #agreements.join(entities).on(agreement[:entity_id].eq(entities[:id]))
    #end

    ## union do
    ## semidifference do

  #end

