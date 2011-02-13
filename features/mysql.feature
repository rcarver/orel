Feature: Create MySQL tables from relational definitions

  Scenario: Create a table with an auto increment integer key
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key :id, Orel::Domains::Serial
        end
      end
      """
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
      CREATE TABLE `user` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        UNIQUE KEY `user_id` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """

  Scenario: Create a table with a composite primary key
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key :first_name, Orel::Domains::String
          key :last_name, Orel::Domains::String
        end
      end
      """
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
      CREATE TABLE `user` (
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `user_first_name_last_name` (`first_name`,`last_name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """

  Scenario: Create a table with basic column types
    Given I have these class definitions:
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
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
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
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """

  Scenario: Create multiple relations for one class
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key :id,   Orel::Domains::Serial
          att :name, Orel::Domains::String
        end
        heading :deleted do
          att :at, Orel::Domains::DateTime
        end
      end
      """
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
      CREATE TABLE `user` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `user_id` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `user_deleted` (
        `user_id` int(11) NOT NULL,
        `at` datetime NOT NULL,
        UNIQUE KEY `user_deleted_user_id` (`user_id`),
        CONSTRAINT `user_deleted_user_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """

  Scenario: Create multiple relations for one class with a composite key
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key :first_name, Orel::Domains::String
          key :last_name, Orel::Domains::String
        end
        heading :deleted do
          att :at, Orel::Domains::DateTime
        end
      end
      """
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
      CREATE TABLE `user` (
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `user_first_name_last_name` (`first_name`,`last_name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `user_deleted` (
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        `at` datetime NOT NULL,
        UNIQUE KEY `user_deleted_first_name_last_name` (`first_name`,`last_name`),
        CONSTRAINT `user_deleted_user_fk` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `user` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """



