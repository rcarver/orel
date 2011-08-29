require 'helper'

describe Orel::Relation do
  subject { UsersAndThings::User }

  describe ".connection" do
    it "gives you a connection" do
      subject.connection.should be_an_instance_of(Orel::Connection)
    end
    it "uses the base active record connection by default" do
      pending
    end
    it "uses a configured active record connection" do
      pending
    end
  end

  describe ".get_heading" do
    it "returns the base heading" do
      subject.get_heading.name.should == :users_and_things_users
    end
    it "returns a child heading" do
      pending
    end
    it "raises an error if asking for a non-existent child" do
      expect {
        subject.get_heading(:no_child_name)
      }.to raise_error(RuntimeError, "UsersAndThings::User has no heading :no_child_name")
    end
  end

  describe ".table" do
    it "returns a table for the base heading" do
      subject.table.should be_an_instance_of(Orel::Table)
    end
    it "returns a table for a child heading" do
      pending
    end
    it "raises an error if asking for a non-existent child" do
      expect {
        subject.table(:no_child_name)
      }.to raise_error(RuntimeError, "UsersAndThings::User has no heading :no_child_name")
    end
  end
end
