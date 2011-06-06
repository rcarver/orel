require 'helper'

describe Orel::Relation do
  subject { UsersAndThings::User }

  describe "#get_heading" do
    it "can return the base heading" do
      subject.get_heading.name.should == :users_and_things_users
    end
    it "can return a child heading"
    it "raises an error if asking for a non-existent child" do
      expect {
        subject.get_heading(:no_child_name)
      }.to raise_error(RuntimeError, "No child heading :no_child_name")
    end
  end

  describe "#get_table" do
    it "can return a table for the base heading" do
      subject.get_table.should be_an_instance_of(Orel::Table)
    end
    it "can return a table for a child heading"
    it "raises an error if asking for a non-existent child" do
      expect {
        subject.get_table(:no_child_name)
      }.to raise_error(RuntimeError, "No child heading :no_child_name")
    end
  end
end
