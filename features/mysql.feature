Feature: Create MySQL tables from relational definitions

  Scenario: Create a table with a auto increment integer key
    Given a file named "agreement.rb" with:
      """
      class User
        extend Orel::Relation
        heading do
          key :id, Orel::Domains::Serial
        end
      end
      """
    And a file named "sample.rb" with:
      """
      require 'orel/test'
      require 'agreement'
      Orel.drop_tables!
      Orel.create_tables!

      puts "begin"
      User.sql.show_create_tables.each { |c| puts c }
      puts "end"
      """
    When I run "ruby -I ../lib sample.rb"
    Then the output should contain:
      """
      begin
      CREATE TABLE `user` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        UNIQUE KEY `user_id` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      end
      """

  Scenario: Create a table with a composite primary key
    Given a file named "agreement.rb" with:
      """
      class User
        extend Orel::Relation
        heading do
          key :first_name, Orel::Domains::String
          key :last_name, Orel::Domains::String
        end
      end
      """
    And a file named "sample.rb" with:
      """
      require 'orel/test'
      require 'agreement'
      Orel.drop_tables!
      Orel.create_tables!

      puts "begin"
      User.sql.show_create_tables.each { |c| puts c }
      puts "end"
      """
    When I run "ruby -I ../lib sample.rb"
    Then the output should contain:
      """
      begin
      CREATE TABLE `user` (
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `user_first_name_last_name` (`first_name`,`last_name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      end
      """

  Scenario: Create a table with basic column types
    Given a file named "agreement.rb" with:
      """
      class User
        extend Orel::Relation
        heading do
          key :id,     Orel::Domains::Serial
          att :name,   Orel::Domains::String
          att :age,    Orel::Domains::Integer
          att :height, Orel::Domains::Float
          att :at,     Orel::Domains::DateTime
          att :on,     Orel::Domains::Date
          att :bio,    Orel::Domains::Text
          att :good,   Orel::Domains::Boolean
        end
      end
      """
    And a file named "sample.rb" with:
      """
      require 'orel/test'
      require 'agreement'
      Orel.drop_tables!
      Orel.create_tables!

      puts "begin"
      User.sql.show_create_tables.each { |c| puts c }
      puts "end"
      """
    When I run "ruby -I ../lib sample.rb"
    Then the output should contain:
      """
      begin
      CREATE TABLE `user` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `age` int(11) NOT NULL,
        `height` float NOT NULL,
        `at` datetime NOT NULL,
        `on` date NOT NULL,
        `bio` text NOT NULL,
        `good` tinyint(1) NOT NULL,
        UNIQUE KEY `user_id` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      end
      """
