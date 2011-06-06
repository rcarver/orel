require 'helper'

describe Orel::Relation do
  subject { UsersAndThings::User }

  describe "#get_heading" do
    it "returns the base heading" do
      subject.get_heading.name.should == :users_and_things_users
    end
    it "returns a child heading"
    it "raises an error if asking for a non-existent child" do
      expect {
        subject.get_heading(:no_child_name)
      }.to raise_error(RuntimeError, "No child heading :no_child_name")
    end
  end

  describe "#table" do
    it "returns a table for the base heading" do
      subject.table.should be_an_instance_of(Orel::Table)
    end
    it "returns a table for a child heading"
    it "raises an error if asking for a non-existent child" do
      expect {
        subject.table(:no_child_name)
      }.to raise_error(RuntimeError, "No child heading :no_child_name")
    end
  end
end
