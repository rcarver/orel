@sql @mysql
Feature: Perform MySQL operations

  Background:
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key { id }
          att :id, Orel::Domains::Serial
          att :name, Orel::Domains::String
        end
      end
      """

  Scenario: Perform an insert
    When I run some Orel code:
      """
      table = Orel::Sql::Table.new(User.get_heading)
      insert_statement = table.insert_statement(:name => "John")
      puts insert_statement
      Orel.execute(insert_statement)
      Orel.query("SELECT id, name from user").each { |row|
        puts row.join(',')
      }
      puts "done"
      """
    Then the output should contain:
      """
      INSERT INTO `user` (`name`) VALUES ('John')
      1,John
      done
      """

  Scenario: Perform an update
    When I run some Orel code:
      """
      table = Orel::Sql::Table.new(User.get_heading)
      insert_statement = table.insert_statement(:name => "John")
      id = Orel.insert(insert_statement)
      update_statement = table.update_statement({ :name => "Joe" }, { :id => id })
      puts update_statement
      Orel.insert(update_statement)
      Orel.query("SELECT id, name from user").each { |row|
        puts row.join(',')
      }
      puts "done"
      """
    Then the output should contain:
      """
      UPDATE `user` SET `name` = 'Joe' WHERE `user`.`id` = 1
      1,Joe
      done
      """

  Scenario: Perform a delete
    When I run some Orel code:
      """
      table = Orel::Sql::Table.new(User.get_heading)
      insert_statement1 = table.insert_statement(:name => "John")
      insert_statement2 = table.insert_statement(:name => "Joe")
      id1 = Orel.insert(insert_statement1)
      id2 = Orel.insert(insert_statement2)
      delete_statement = table.delete_statement(:id => id1)
      puts delete_statement
      Orel.insert(delete_statement)
      Orel.query("SELECT id, name from user").each { |row|
        puts row.join(',')
      }
      puts "done"
      """
    Then the output should contain:
      """
      DELETE FROM `user` WHERE `user`.`id` = 1
      2,Joe
      done
      """

