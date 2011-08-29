require 'bundler/setup'
require 'mysql2'

DB = "orel_mysql_test"
$connection = Mysql2::Client.new(:username => "root", :password => nil)
$connection.query("drop database if exists #{DB}")
$connection.query("create database #{DB}")
$connection.query("use #{DB}")

results = {
  :key_length => nil,
  :constraint_length => nil
}

key_length = nil
begin
  (60..100).each do |index|
    key_name = "a" * index
    table = <<-SQL
      CREATE TABLE `key_length#{index}` (
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `#{key_name}` (`name`)
      ) ENGINE=InnoDB;
    SQL
    $connection.query(table)
    key_length = index
  end
rescue StandardError => e
  results[:key_length] = key_length
end
puts "max key length: #{results[:key_length].inspect}"

constraint_length = nil
begin
  table = <<-SQL
    CREATE TABLE `constraint_base` (
      `name` varchar(255) NOT NULL,
      UNIQUE KEY `name` (`name`)
    ) ENGINE=InnoDB;
  SQL
  $connection.query(table)
  (60..100).each do |index|
    constraint_name = "a" * index
    table = <<-SQL
      CREATE TABLE `constraint_length#{index}` (
        `name` varchar(255) NOT NULL,
        KEY `name` (`name`),
        CONSTRAINT `#{constraint_name}` FOREIGN KEY (`name`) REFERENCES `constraint_base` (`name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB;
    SQL
    $connection.query(table)
    constraint_length = index
  end
rescue StandardError => e
  results[:constraint_length] = constraint_length
end
puts "max constraint length: #{results[:constraint_length].inspect}"
