require 'helper'

describe Orel::Attributes do

  let(:thing_heading) {
    UsersAndThings::Thing.get_heading
  }

  let(:user) {
    UsersAndThings::User.new :first_name => "John", :last_name => "Smith"
  }

  subject {
    Orel::Attributes.new(thing_heading)
  }

  it "can tell you if it has an attribute or not" do
    subject.att?(:name).should be_true
    subject.att?(:foo).should be_false
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

  it "can set values for a reference" do
    subject[:first_name].should be_nil
    subject[:last_name].should be_nil
    subject[UsersAndThings::User] = user
    subject[:first_name].should == "John"
    subject[:last_name].should == "Smith"
  end

  it "can give you a hash of current values" do
    subject[:name] = "Box"
    subject[UsersAndThings::User] = user
    subject.hash.should == { :name => "Box", :first_name => "John", :last_name => "Smith" }
  end

  specify "if you modify the hash of current values it doesn't affect the real values" do
    subject[:name] = "Box"
    hash = subject.hash
    hash[:name] = "Junk"
    subject[:name].should == "Box"
  end
end

