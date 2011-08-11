require 'helper'

describe Orel::SimpleAssociations do

  let(:relation_set) { UsersAndThings::User.relation_set }
  let(:parent) { UsersAndThings::User.create(:first_name => "John", :last_name => "Smith", :age => 33) }

  subject {
    described_class.new(parent, relation_set)
  }

  it "can determine whether an association exists or not" do
    subject.should be_include(:status)
    subject.should be_include(:ips)
    subject.should_not be_include(:other)
  end

  context "a 1:1 association" do
    context "before it's set" do
      it "is nil" do
        subject[:status].nil?
      end
    end
    context "after it's set" do
      before do
        subject[:status] = { :value => "ok" }
      end
      it "returns the data" do
        subject[:status].value.should == "ok"
      end
    end
  end

  context "a M:1 association" do
    context "before it's set" do
      it "is empty" do
        subject[:ips].size.should == 0
        subject[:ips].should be_empty
      end
    end
    context "when data is appended" do
      before do
        subject[:ips] << { :ip => "127.0.0.1" }
        subject[:ips] << { :ip => "192.168.0.1" }
      end
      it "provides the data like an array" do
        subject[:ips].size.should == 2
        subject[:ips].should_not be_empty
        subject[:ips].to_a.should =~ [{ :ip => "127.0.0.1" }, { :ip => "192.168.0.1" }]
        subject[:ips].map.should =~ [{ :ip => "127.0.0.1" }, { :ip => "192.168.0.1" }]
      end
    end
  end

end
