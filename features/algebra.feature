@wip
Feature: Perform relational algebra

  Scenario: Perform a projection
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        extend Orel::Algebra
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      User.create :first_name => "John", :last_name => "Smith"
      User.create :first_name => "Mary", :last_name => "Smith"
      projection = User.project
      Orel::Test.wrap {
        projection.each { |tuple|
          puts [tuple[:first_name], tuple[:last_name]].join(",")
        }
      }
      """
    Then the output should contain:
      """
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
        extend Orel::Algebra
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      User.create :first_name => "John", :last_name => "Smith"
      User.create :first_name => "Mary", :last_name => "Smith"
      restriction = User.restrict(:first_name => "John")
      puts restriction.count
      Orel::Test.wrap {
        restriction.project.each { |tuple|
          puts [tuple[:first_name], tuple[:last_name]].join(",")
        }
      }
      """
    Then the output should contain:
      """
      1
      ---
      John,Smith
      ---
      """

  Scenario: Perform a natural join
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        extend Orel::Algebra
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      class Thing
        extend Orel::Relation
        extend Orel::Algebra
        heading do
          key { User / name }
          ref User
          att :name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      john = User.create :first_name => "John", :last_name => "Smith"
      mary = User.create :first_name => "Mary", :last_name => "Smith"
      Thing.create :user => john, :name => "Car"
      Thing.create :user => john, :name => "Boat"
      Thing.create :user => mary, :name => "Boat"
      join = User.natual_join(Thing)
      puts join.count
      Orel::Test.wrap {
        join.project.each { |tuple|
          puts [tuple[:first_name], tuple[:last_name], tuple[:name]].join(",")
        }
      }
      """
    Then the output should contain:
      """
      3
      ---
      John,Smith,Car
      John,Smith,Boat
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

