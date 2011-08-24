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
    end
    specify "the records are writable" do
      subject[UsersAndThings::Thing][0].should_not be_readonly
    end
    specify "the records are queryable" do
      subject[UsersAndThings::Thing][0].should_not be_locked_for_query
    end
    specify "the records are NEW instances" do
      thing1b = subject[UsersAndThings::Thing].find { |r| r.name == "table" }
      thing1b.object_id.should_not == thing1.object_id
    end
    it "raises an error when it's locked for query" do
      subject.locked_for_query = true
      expect { subject[UsersAndThings::Thing] }.to raise_error(Orel::LockedForQueryError)
    end
    context "when records are already available" do
      before do
        @a = subject[UsersAndThings::Thing].find { |r| r.name == "table" }
      end
      it "returns the previously retrieved record" do
        b = subject[UsersAndThings::Thing].find { |r| r.name == "table" }
        @a.object_id.should == b.object_id
      end
      it "does not throw locked for query errors" do
        subject.locked_for_query = true
        expect { subject[UsersAndThings::Thing] }.not_to raise_error(Orel::LockedForQueryError)
      end
    end
    context "when records have been stored" do
      before do
        subject._store(UsersAndThings::Thing, { :name => "test" })
      end
      it "returns stored records" do
        subject[UsersAndThings::Thing].size.should == 1
        subject[UsersAndThings::Thing].first.name.should == "test"
      end
      it "does not throw locked for query errors" do
        subject.locked_for_query = true
        expect { subject[UsersAndThings::Thing] }.not_to raise_error(Orel::LockedForQueryError)
      end
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
    specify "the record is writable" do
      subject[UsersAndThings::User].should_not be_readonly
    end
    specify "the record is queryable" do
      subject[UsersAndThings::User].should_not be_locked_for_query
    end
    specify "the record is a NEW instance" do
      subject[UsersAndThings::User].object_id.should_not == user.object_id
    end
    it "raises an error when it's locked for read" do
      subject.locked_for_query = true
      expect { subject[UsersAndThings::User] }.to raise_error(Orel::LockedForQueryError)
    end
    context "when records are already available" do
      before do
        @a = subject[UsersAndThings::User]
      end
      it "returns the previously retrieved record" do
        b = subject[UsersAndThings::User]
        @a.object_id.should == b.object_id
      end
      it "does not throw locked for query errors" do
        subject.locked_for_query = true
        expect { subject[UsersAndThings::User] }.not_to raise_error(Orel::LockedForQueryError)
      end
    end
    context "when records have been stored" do
      before do
        subject._store(UsersAndThings::User, { :first_name => "test" })
      end
      it "returns stored records" do
        subject[UsersAndThings::User].first_name.should == "test"
      end
      it "does not throw locked for query errors" do
        subject.locked_for_query = true
        expect { subject[UsersAndThings::User] }.not_to raise_error(Orel::LockedForQueryError)
      end
    end
  end

end
