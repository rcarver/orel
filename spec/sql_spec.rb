require 'helper'

describe Orel::Sql::Table do
  subject { described_class.new(UsersAndThings::User.get_heading) }
  specify "#insert_statement" do
    sql = subject.insert_statement(:first_name => "John")
    sql.should == %{INSERT INTO `users_and_things_user` (`first_name`) VALUES ('John')}
  end
  specify "#update_statement" do
    sql = subject.update_statement({ :first_name => "John" }, { :last_name => "Smith" })
    sql.should == %{UPDATE `users_and_things_user` SET `first_name` = 'John' WHERE `users_and_things_user`.`last_name` = 'Smith'}
  end
  specify "#delete_statement" do
    sql = subject.delete_statement(:first_name => "John")
    sql.should == %{DELETE FROM `users_and_things_user` WHERE `users_and_things_user`.`first_name` = 'John'}
  end
end
