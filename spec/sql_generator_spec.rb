require 'helper'

describe Orel::SqlGenerator::Table do

  let(:klass) { UsersAndThings::User }
  let(:namer) { Orel::Relation::Namer.for_class(klass) }

  subject { described_class.new(namer, klass.get_heading) }

  its(:name) { should == :users_and_things_users }

  specify "#insert_statement" do
    sql = subject.insert_statement(:first_name => "John", :last_name => "Smith", :age => 30)
    sql.should == %{INSERT INTO `users_and_things_users` (`age`, `first_name`, `last_name`) VALUES (30, 'John', 'Smith')}
  end

  specify "#upsert_statement with :increment" do
    sql = subject.upsert_statement({ :first_name => "John", :last_name => "Smith", :age => 30 }, { :values => [:age], :with => :increment })
    sql.should == %{INSERT INTO `users_and_things_users` (`age`, `first_name`, `last_name`) VALUES (30, 'John', 'Smith') ON DUPLICATE KEY UPDATE age=age+VALUES(age)}
  end

  specify "#upsert_statement with :replace" do
    sql = subject.upsert_statement({ :first_name => "John", :last_name => "Smith", :age => 30 }, { :values => [:age], :with => :replace })
    sql.should == %{INSERT INTO `users_and_things_users` (`age`, `first_name`, `last_name`) VALUES (30, 'John', 'Smith') ON DUPLICATE KEY UPDATE age=VALUES(age)}
  end

  specify "#update_statement" do
    sql = subject.update_statement({ :first_name => "John" }, { :last_name => "Smith" })
    sql.should == %{UPDATE `users_and_things_users` SET `first_name` = 'John' WHERE `users_and_things_users`.`last_name` = 'Smith'}
  end

  specify "#delete_statement" do
    sql = subject.delete_statement(:first_name => "John")
    sql.should == %{DELETE FROM `users_and_things_users` WHERE `users_and_things_users`.`first_name` = 'John'}
  end
end
