require 'bundler/setup'
require 'mysql2'

DB = "orel_mysql_test"
$connection = Mysql2::Client.new(:username => "root", :password => nil)
$connection.query("drop database if exists #{DB}")
$connection.query("create database #{DB}")
$connection.query("use #{DB}")

begin
  2.times { |index|
    table = <<-SQL
      CREATE TABLE `a#{index}` (
        `name` varchar(255) NOT NULL,
        KEY `name` (`name`)
      ) ENGINE=InnoDB;
    SQL
    $connection.query(table)
  }
  puts "a key name may be used in multiple tables"
rescue => e
  puts "key names must be unique across the database"
  puts " > #{e.inspect}"
end

begin
  table = <<-SQL
    CREATE TABLE `constraint_base` (
      `name` varchar(255) NOT NULL,
      UNIQUE KEY `name` (`name`)
    ) ENGINE=InnoDB;
  SQL
  $connection.query(table)
  2.times { |index|
    table = <<-SQL
      CREATE TABLE `b#{index}` (
        `name` varchar(255) NOT NULL,
        KEY `name` (`name`),
        CONSTRAINT `name_fk` FOREIGN KEY (`name`) REFERENCES `constraint_base` (`name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB;
    SQL
    $connection.query(table)
  }
  puts "a constraint name may be used in multiple tables"
rescue => e
  puts "constraint names must be unique across the database"
end

