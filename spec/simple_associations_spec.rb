require 'helper'

describe Orel::SimpleAssociations, "on a class with natural keys" do

  let(:relation_set) { UsersAndThings::User.relation_set }
  let(:parent) { UsersAndThings::User.create(:first_name => "John", :last_name => "Smith", :age => 33) }

  describe "in general" do
    subject { described_class.new(parent, relation_set) }
    it "can determine whether an association exists or not" do
      subject.should be_include(:status)
      subject.should be_include(:ips)
      subject.should_not be_include(:other)
    end
    it "raises an error when it's locked for read" do
      subject.locked_for_query = true
      expect { subject[:status] }.to raise_error(Orel::LockedForQueryError)
      expect { subject[:ips] }.to raise_error(Orel::LockedForQueryError)
    end
  end

  describe "reading and writing" do
    subject { described_class.new(parent, relation_set) }

    context "a 1:1 association" do
      context "before it's set" do
        it "is nil" do
          subject[:status].should be_nil
        end
        it "throws an error if you access a property" do
          expect { subject[:status].value }.to raise_error(NoMethodError, "The 1:1 association is nil")
        end
      end
      context "after it's set" do
        before do
          subject[:status] = { :value => "ok" }
        end
        it "returns the data" do
          subject[:status].value.should == "ok"
          subject[:status].to_hash.should == { :value => "ok" }
        end
      end
      context "#save" do
        before do
          subject[:status] = { :value => "ok" }
        end
        let(:table) { UsersAndThings::User.table(:status) }
        it "persists the record" do
          expect { subject.save }.to change(table, :row_count).from(0).to(1)
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
          subject[:ips].map { |r| r.to_hash }.should =~ [{ :ip => "127.0.0.1" }, { :ip => "192.168.0.1" }]
        end
      end
      context "#save" do
        before do
          subject[:ips] << { :ip => "127.0.0.1" }
          subject[:ips] << { :ip => "192.168.0.1" }
        end
        let(:table) { UsersAndThings::User.table(:ips) }
        it "persists the records" do
          expect { subject.save }.to change(table, :row_count).from(0).to(2)
        end
      end
    end
  end

  describe "retrieving data from a persisted instance" do
    let(:instance1) { described_class.new(parent, relation_set) }
    subject         { described_class.new(parent, relation_set) }

    context "a 1:1 association" do
      context "without data" do
        it "is nil" do
          subject[:status].should be_nil
        end
      end
      context "with data" do
        before do
          instance1[:status] = { :value => "ok" }
          instance1.save
        end
        it "has the data" do
          subject[:status].should_not be_nil
          subject[:status].value.should == "ok"
          subject[:status].to_hash.should == { :value => "ok" }
        end
      end
    end

    context "a M:1 association" do
      context "without data" do
        it "is empty" do
          subject[:ips].should be_empty
        end
      end
      context "with data" do
        before do
          instance1[:ips] << { :ip => "127.0.0.1" }
          instance1[:ips] << { :ip => "192.168.0.1" }
          instance1.save
        end
        it "has the records" do
          subject[:ips].map { |r| r.to_hash }.should =~ [{ :ip => "127.0.0.1" }, { :ip => "192.168.0.1" }]
        end
      end
    end
  end
end

describe Orel::SimpleAssociations, "on a class with a surrogate key" do
  pending
end
