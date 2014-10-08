require 'helper'

describe Orel::Attributes do

  let(:thing_heading) {
    UsersAndThings::Thing.get_heading
  }

  let(:user) {
    UsersAndThings::User.new :first_name => "John", :last_name => "Smith"
  }

  describe ".new" do
    it "can be instantiated with default values" do
      attrs = Orel::Attributes.new(thing_heading, :name => "John")
      attrs[:name].should == "John"
    end
    it "can be instantiated without default values" do
      attrs = Orel::Attributes.new(thing_heading)
      attrs[:name].should be_nil
    end
  end

  describe "in general" do
    subject {
      Orel::Attributes.new(thing_heading)
    }
    it "can tell you if any attributes have been set or not" do
      subject.should be_empty
      subject[:name] = "Box"
      subject.should_not be_empty
    end
    it "can tell you if it has an attribute or not" do
      subject.att?(:name).should be_truthy
      subject.att?(:foo).should be_falsey
    end
    it "can get and set the value of an attribute" do
      subject[:name].should be_nil
      subject[:name] = "Box"
      subject[:name].should == "Box"
    end
    it "throws an error if you ask for an attribute that doesn't exist" do
      expect { subject[:foo] }.to raise_error(Orel::Attributes::InvalidAttribute)
    end
    it "throws an error if try to set an attribute that doesn't exist" do
      expect { subject[:foo] = "bar" }.to raise_error(Orel::Attributes::InvalidAttribute)
    end
    it "throws an error if you set an attribute in readonly mode" do
      subject.readonly = true
      expect { subject[:name] = "bar" }.to raise_error(Orel::ReadonlyError)
    end
    it "can set values for a reference" do
      subject[:first_name].should be_nil
      subject[:last_name].should be_nil
      subject[UsersAndThings::User] = user
      subject[:first_name].should == "John"
      subject[:last_name].should == "Smith"
    end
    it "raises an error if you pass the wrong type of object for a reference" do
      expect { subject[UsersAndThings::User] = Object.new }.to raise_error(ArgumentError)
    end
    it "raises an error if you pass a class that isn't a reference" do
      expect { subject[UsersAndThings::Thing] = UsersAndThings::Thing.new }.to raise_error(Orel::Attributes::InvalidReference)
    end
    it "can give you a hash of current values" do
      subject[:name] = "Box"
      subject[UsersAndThings::User] = user
      subject.to_hash.should == { :name => "Box", :first_name => "John", :last_name => "Smith" }
    end
    specify "if you modify the hash of current values it doesn't affect the real values" do
      subject[:name] = "Box"
      hash = subject.to_hash
      hash[:name] = "Junk"
      subject[:name].should == "Box"
    end
  end

  describe "conformance to ActiveModel::Dirty" do
    describe "at first, without default values" do
      subject { Orel::Attributes.new(thing_heading) }
      its(:changed?) { should be_falsey }
      its(:changed) { should be_empty }
      its(:changes) { should be_empty }
      its(:previous_changes) { should be_empty }
      its(:changed_attributes) { should be_empty }
    end
    describe "at first, with default values" do
      subject { Orel::Attributes.new(thing_heading, :name => "John") }
      its(:changed?) { should be_falsey }
      its(:changed) { should be_empty }
      its(:changes) { should be_empty }
      its(:previous_changes) { should be_empty }
      its(:changed_attributes) { should be_empty }
    end
    describe "when changed, without default values" do
      subject { Orel::Attributes.new(thing_heading) }
      before do
        subject[:name] = "Bob"
      end
      its(:changed?) { should be_truthy }
      its(:changed) { should == [:name] }
      its(:changes) { should == { :name => [nil, 'Bob'] } }
      its(:previous_changes) { should be_empty }
      its(:changed_attributes) { should == { :name => nil } }
    end
    describe "when changed, with default values" do
      subject { Orel::Attributes.new(thing_heading, :name => "John") }
      before do
        subject[:name] = "Bob"
      end
      its(:changed?) { should be_truthy }
      its(:changed) { should == [:name] }
      its(:changes) { should == { :name => ['John', 'Bob'] } }
      its(:previous_changes) { should be_empty }
      its(:changed_attributes) { should == { :name => 'John' } }
    end
  end
end

