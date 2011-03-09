require 'helper'
require 'test/unit/assertions'
require 'active_model/lint'

describe "Conformance to ActiveModel::Lint" do
  include Test::Unit::Assertions
  include ActiveModel::Lint::Tests

  class ActiveModelNamingCompatible
    include Orel::Object
    heading do
      att :name, Orel::Domains::String
    end
  end

  # Convert Lint's tests into RSpec examples.
  ActiveModel::Lint::Tests.public_instance_methods.each do |m|
    if m.to_s =~ /^test_/
      example m.gsub('_',' ') do
        send m
      end
    end
  end

  let(:model) { ActiveModelNamingCompatible.new }
end

describe "ActiveModel details" do

  let(:user) {
    UsersAndThings::User.new(:first_name => "John", :last_name => "Smith")
  }

  let(:thing) {
    UsersAndThings::Thing.new(UsersAndThings::User => user, :name => "Box")
  }

  describe "#to_param" do
    it "returns nil if the record is not persisted" do
      user.to_param.should be_nil
      thing.to_key.should be_nil
    end
    it "returns a string id if the record has a single key and is persisted" do
      user.save
      thing.save
      thing.to_param.should be_an_instance_of(String)
      thing.to_param.should match(/^\d$/)
    end
    it "returns a comma delimited string if the record has a composite key and is persisted" do
      user.save
      user.to_param.should be_an_instance_of(String)
      user.to_param.should == "John,Smith"
    end
  end

  describe "#to_key" do
    it "returns nil if the record is not persisted" do
      user.to_key.should be_nil
      thing.to_key.should be_nil
    end
    it "returns a single item array if the record has a single key and is persisted" do
      user.save
      thing.save
      thing.id.should_not be_nil
      thing.to_key.should == [thing.id]
    end
    it "returns an array of all key values if record has a composite key and is persisted" do
      user.save
      user.to_key.should == ["John", "Smith"]
    end
  end
end
