@sql @mysql
Feature: Perform MySQL operations

  Scenario: Perform an insert and see records in a table
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

  Scenario: Perform an update and see changes in a table
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
    When I run some Orel code:
      """
      table = Orel::Sql::Table.new(User.get_heading)
      insert_statement = table.insert_statement(:name => "John")
      id = Orel.insert(insert_statement)
      update_statement = table.update_statement({ :id => id }, { :name => "Joe" })
      puts update_statement
      Orel.insert(update_statement)
      Orel.query("SELECT id, name from user").each { |row|
        puts row.join(',')
      }
      puts "done"
      """
    Then the output should contain:
      """
      UPDATE `user` SET `name`='Joe' WHERE `id`=1
      1,Joe
      done
      """

