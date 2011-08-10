require 'helper'

describe Orel::Object, "validation" do

  describe "an object with no values for its attributes" do
    subject { UsersAndThings::User.new }
    it { should_not be_valid }
  end

  describe "an object with values for its attributes" do
    subject { UsersAndThings::User.new :first_name => "John", :last_name => "Smith", :age => 27 }
    it { should be_valid }
  end

  describe "the errors for an object" do
    subject { UsersAndThings::User.new }
    it "has no information before checking validity" do
      subject.errors.size.should == 0
    end
    it "provides error messages for invalid attributes" do
      subject.should_not be_valid
      subject.errors.size.should > 0
      subject.errors[:first_name].should == ["cannot be blank"]
    end
    it "provides ActiveModel i18n compatible error keys"
  end
end

describe Orel::Object do
  let(:invalid_attrs) { {} }
  let(:valid_attrs)   { { :first_name => "John", :last_name => "Doe", :age => 33 } }

  describe "creating new records" do
    context "an invalid record" do
      specify ".create returns an invalid record and does not persist anything" do
        result = UsersAndThings::User.create(invalid_attrs)
        result.should be_an_instance_of(UsersAndThings::User)
        result.should_not be_valid
        result.should_not be_persisted
        UsersAndThings::User.table.row_count.should == 0
      end
      specify ".create! raises an error and does not persist anything" do
        expect { UsersAndThings::User.create!(invalid_attrs) }.to raise_error(Orel::Object::InvalidRecord)
        UsersAndThings::User.table.row_count.should == 0
      end
    end
    context "a valid record" do
      specify ".create returns a valid and persisted record" do
        result = UsersAndThings::User.create(valid_attrs)
        result.should be_an_instance_of(UsersAndThings::User)
        result.should be_valid
        result.should be_persisted
        UsersAndThings::User.table.row_count.should == 1
      end
      specify ".create! returns a valid and persisted record" do
        result = UsersAndThings::User.create(valid_attrs)
        result.should be_an_instance_of(UsersAndThings::User)
        result.should be_valid
        result.should be_persisted
        UsersAndThings::User.table.row_count.should == 1
      end
    end
  end

  describe "#save" do
    context "a new invalid record" do
      subject { UsersAndThings::User.new(invalid_attrs) }
      it "returns false and does not persist the record" do
        subject.save.should be_false
        UsersAndThings::User.table.row_count.should == 0
      end
    end
    context "a new valid record" do
      subject { UsersAndThings::User.new(valid_attrs) }
      it "returns true and persists the record" do
        subject.save.should be_true
        UsersAndThings::User.table.row_count.should == 1
      end
    end
  end
end
