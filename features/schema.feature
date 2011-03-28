@schema @mysql
Feature: Create MySQL tables from relational definitions

  Scenario: Create a table with surrogate
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key { id }
          att :id, Orel::Domains::Serial
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

  Scenario: Create a table with a natural key
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
          key { id }
          att :id,     Orel::Domains::Serial
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

  Scenario: Create child one-to-one and one-to-many relationships within a class using a surrogate key
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key { id }
          att :id, Orel::Domains::Serial
          att :name, Orel::Domains::String
        end
        heading :deleted do
          key { User }
          att :at, Orel::Domains::DateTime
        end
        heading :logins do
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
        `at` datetime NOT NULL,
        `user_id` int(11) NOT NULL,
        UNIQUE KEY `user_deleted_user_id` (`user_id`),
        CONSTRAINT `user_deleted_user_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `user_logins` (
        `at` datetime NOT NULL,
        `user_id` int(11) NOT NULL,
        KEY `user_logins_user_fk` (`user_id`),
        CONSTRAINT `user_logins_user_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """

  Scenario: Create child one-to-one and one-to-many relationships within a class using a natural key
    Given I have these class definitions:
      """
      class User
        extend Orel::Relation
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
        heading :deleted do
          key { User }
          att :at, Orel::Domains::DateTime
        end
        heading :logins do
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
        `at` datetime NOT NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `user_deleted_first_name_last_name` (`first_name`,`last_name`),
        CONSTRAINT `user_deleted_user_fk` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `user` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `user_logins` (
        `at` datetime NOT NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        KEY `user_logins_user_fk` (`first_name`,`last_name`),
        CONSTRAINT `user_logins_user_fk` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `user` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """

  Scenario: Create a one-to-many relationship using surrogate keys
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
      class Thing
        extend Orel::Relation
        heading do
          key { id }
          att :id, Orel::Domains::Serial
          att :name, Orel::Domains::String
          ref User
        end
      end
      """
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
      CREATE TABLE `thing` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `user_id` int(11) NOT NULL,
        UNIQUE KEY `thing_id` (`id`),
        KEY `thing_user_fk` (`user_id`),
        CONSTRAINT `thing_user_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `user` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `user_id` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """

  Scenario: Create a one-to-many relationship using natural keys
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
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
      CREATE TABLE `thing` (
        `name` varchar(255) NOT NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `thing_first_name_last_name_name` (`first_name`,`last_name`,`name`),
        CONSTRAINT `thing_user_fk` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `user` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `user` (
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `user_first_name_last_name` (`first_name`,`last_name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """

  Scenario: Create a many-to-many relationship with natural keys
    Given I have these class definitions:
      """
      class Supplier
        extend Orel::Relation
        heading do
          key { sno }
          att :sno, Orel::Domains::String
          att :name, Orel::Domains::String
        end
      end
      class Part
        extend Orel::Relation
        heading do
          key { pno }
          att :pno, Orel::Domains::String
          att :name, Orel::Domains::String
        end
      end
      class Shipment
        extend Orel::Relation
        heading do
          key { Supplier / Part }
          ref Supplier
          ref Part
          att :qty, Orel::Domains::Integer
        end
      end
      """
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
      CREATE TABLE `part` (
        `pno` varchar(255) NOT NULL,
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `part_pno` (`pno`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `shipment` (
        `qty` int(11) NOT NULL,
        `sno` varchar(255) NOT NULL,
        `pno` varchar(255) NOT NULL,
        UNIQUE KEY `shipment_sno_pno` (`sno`,`pno`),
        KEY `shipment_part_fk` (`pno`),
        CONSTRAINT `shipment_part_fk` FOREIGN KEY (`pno`) REFERENCES `part` (`pno`) ON DELETE NO ACTION ON UPDATE NO ACTION,
        CONSTRAINT `shipment_supplier_fk` FOREIGN KEY (`sno`) REFERENCES `supplier` (`sno`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `supplier` (
        `sno` varchar(255) NOT NULL,
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `supplier_sno` (`sno`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """


