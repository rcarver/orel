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
