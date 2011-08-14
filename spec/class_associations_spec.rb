require 'helper'

describe Orel::ClassAssociations do

  let(:user)   { UsersAndThings::User.create!(:first_name => "John", :last_name => "Smith", :age => 33) }
  let(:thing1) { UsersAndThings::Thing.create!(UsersAndThings::User => user, :name => "table") }
  let(:thing2) { UsersAndThings::Thing.create!(UsersAndThings::User => user, :name => "chair") }

  before do
    [user, thing1, thing2] # touch records so they exist
  end

  describe "1:M relation (child)" do
    subject { Orel::ClassAssociations.new(UsersAndThings::User, user.attributes) }

    it "finds all records" do
      subject[UsersAndThings::Thing].should =~ [thing1, thing2]
    end
    specify "the records are persisted" do
      subject[UsersAndThings::Thing][0].should be_persisted
      subject[UsersAndThings::Thing][1].should be_persisted
    end
    specify "the records are NEW instances" do
      thing1b = subject[UsersAndThings::Thing].find { |r| r.name == "table" }
      thing1b.object_id.should_not == thing1.object_id
    end
  end

  describe "M:1 relation (parent)" do
    subject { Orel::ClassAssociations.new(UsersAndThings::Thing, thing1.attributes) }

    it "finds the one record" do
      subject[UsersAndThings::User].should == user
    end
    specify "the record is persisted" do
      subject[UsersAndThings::User].should be_persisted
    end
    specify "the record is a NEW instance" do
      subject[UsersAndThings::User].object_id.should_not == user.object_id
    end
  end

end
