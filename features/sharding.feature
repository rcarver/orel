@shard @mysql
Feature: Automatically shard data into multiple tables

  Scenario: The table is created as a template
    Given I have these class definitions:
      """
      class Count
        extend Orel::Relation
        extend Orel::Sharding
        heading do
          key { day / thing }
          att :day, Orel::Domains::String
          att :thing, Orel::Domains::String
          att :count, Orel::Domains::Integer
        end
        shard_table_on(:day) do |day|
          day[0, 6]
        end
      end
      """
    When I use Orel to fill my database with tables
    Then my database looks like:
      """
      CREATE TABLE `counts_template` (
        `day` varchar(255) NOT NULL,
        `thing` varchar(255) NOT NULL,
        `count` int(11) NOT NULL,
        UNIQUE KEY `c_d_t_139dbd63abf1bc7926aee62e8ac5e276` (`day`,`thing`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """
    When I run some Orel code:
      """
      days = %w(20120101 20120102 20120201)
      days.each do |day|
        Count.table.insert(:day => day, :thing => "ideas", :count => 10)
      end
      days.each do |day|
        table = Count.partition_for(:day => day)
        puts [day, table.name, table.row_count].join(", ")
      end
      rows = Count.table.query { |q, table|
        q.project table[:day], table[:thing], table[:count]
        q.where   table[:day].in(days)
      }
      rows.each { |row|
        puts [row[:day], row[:thing], row[:count]].join(", ")
      }
      """
    Then the output should contain:
      """
      20120101, counts_201201, 2
      20120102, counts_201201, 2
      20120201, counts_201202, 1
      20120101, ideas, 10
      20120102, ideas, 10
      20120201, ideas, 10
      """
    And my database looks like:
      """
      CREATE TABLE `counts_201201` (
        `day` varchar(255) NOT NULL,
        `thing` varchar(255) NOT NULL,
        `count` int(11) NOT NULL,
        UNIQUE KEY `c_d_t_139dbd63abf1bc7926aee62e8ac5e276` (`day`,`thing`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `counts_201202` (
        `day` varchar(255) NOT NULL,
        `thing` varchar(255) NOT NULL,
        `count` int(11) NOT NULL,
        UNIQUE KEY `c_d_t_139dbd63abf1bc7926aee62e8ac5e276` (`day`,`thing`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `counts_template` (
        `day` varchar(255) NOT NULL,
        `thing` varchar(255) NOT NULL,
        `count` int(11) NOT NULL,
        UNIQUE KEY `c_d_t_139dbd63abf1bc7926aee62e8ac5e276` (`day`,`thing`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      """

