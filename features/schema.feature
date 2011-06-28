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
      CREATE TABLE `users` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        UNIQUE KEY `i_b80bb7740288fda1f201890375a60c8f` (`id`)
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
      CREATE TABLE `users` (
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `fn_ln_453236cc5833e48a53bb6efb24da3d77` (`first_name`,`last_name`)
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
          att :time,   Orel::Domains::BigInt
        end
      end
      """
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
      CREATE TABLE `users` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `age` int(11) NOT NULL,
        `height` float NOT NULL,
        `at` datetime NOT NULL,
        `on` date NOT NULL,
        `bio` text NOT NULL,
        `good` tinyint(1) NOT NULL,
        `time` bigint(20) NOT NULL,
        UNIQUE KEY `i_b80bb7740288fda1f201890375a60c8f` (`id`)
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
      CREATE TABLE `user_deleted` (
        `at` datetime NOT NULL,
        `user_id` int(11) NOT NULL,
        UNIQUE KEY `ui_e8701ad48ba05a91604e480dd60899a3` (`user_id`),
        CONSTRAINT `user_deleted_users_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `user_logins` (
        `at` datetime NOT NULL,
        `user_id` int(11) NOT NULL,
        KEY `user_logins_users_fk` (`user_id`),
        CONSTRAINT `user_logins_users_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `users` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `i_b80bb7740288fda1f201890375a60c8f` (`id`)
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
      CREATE TABLE `user_deleted` (
        `at` datetime NOT NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `fn_ln_453236cc5833e48a53bb6efb24da3d77` (`first_name`,`last_name`),
        CONSTRAINT `user_deleted_users_fk` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `users` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `user_logins` (
        `at` datetime NOT NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        KEY `user_logins_users_fk` (`first_name`,`last_name`),
        CONSTRAINT `user_logins_users_fk` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `users` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `users` (
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `fn_ln_453236cc5833e48a53bb6efb24da3d77` (`first_name`,`last_name`)
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
      CREATE TABLE `things` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `user_id` int(11) NOT NULL,
        UNIQUE KEY `i_b80bb7740288fda1f201890375a60c8f` (`id`),
        KEY `things_users_fk` (`user_id`),
        CONSTRAINT `things_users_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `users` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `i_b80bb7740288fda1f201890375a60c8f` (`id`)
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
      CREATE TABLE `things` (
        `name` varchar(255) NOT NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `fn_ln_n_b7f37fdab28b11c9e42cccaee91cd8a3` (`first_name`,`last_name`,`name`),
        CONSTRAINT `things_users_fk` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `users` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `users` (
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `fn_ln_453236cc5833e48a53bb6efb24da3d77` (`first_name`,`last_name`)
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
      CREATE TABLE `parts` (
        `pno` varchar(255) NOT NULL,
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `p_a640dd405e21ee73d9ad0c1153971c0f` (`pno`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `shipments` (
        `qty` int(11) NOT NULL,
        `sno` varchar(255) NOT NULL,
        `pno` varchar(255) NOT NULL,
        UNIQUE KEY `s_p_c2051a7c46108e2d1104c78f78c9862e` (`sno`,`pno`),
        KEY `shipments_parts_fk` (`pno`),
        CONSTRAINT `shipments_parts_fk` FOREIGN KEY (`pno`) REFERENCES `parts` (`pno`) ON DELETE NO ACTION ON UPDATE NO ACTION,
        CONSTRAINT `shipments_suppliers_fk` FOREIGN KEY (`sno`) REFERENCES `suppliers` (`sno`) ON DELETE NO ACTION ON UPDATE NO ACTION
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `suppliers` (
        `sno` varchar(255) NOT NULL,
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `s_96466301bed4aeef20378fe7bb5277e6` (`sno`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """


