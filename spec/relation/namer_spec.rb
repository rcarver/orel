require 'helper'

describe Orel::Relation::Namer do

  describe ".for_class" do
    it "turns a top level class into a namer" do
      namer = described_class.for_class(Object)
      namer.heading_name.should == :objects
    end
    it "turns a namespaced class into a namer" do
      namer = described_class.for_class(Orel::Relation)
      namer.heading_name.should == :orel_relations
    end
  end

  shared_examples_for "a Namer creating names for 'user'" do
    specify "a foreign key name" do
      subject.foreign_key_name(:name).should == :name
    end
    specify "a foreign key name for the attribute 'id'" do
      subject.foreign_key_name(:id).should == :user_id
    end
    specify "a unique key name" do
      subject.unique_key_name([:first_name, :last_name]).should == ('u_fn_ln_' + Digest::MD5.hexdigest('first_name::last_name')).to_sym
    end
    specify "a foreign key constraint name" do
      pending
      # subject.unique_key_name([:first_name, :last_name]).should == :user_first_name_last_name
    end
    specify "the namer for a singular child" do
      namer = subject.for_child(:status)
      namer.heading_name.should == :user_status
    end
    specify "the namer for a plural child" do
      namer = subject.for_child(:logins)
      namer.heading_name.should == :user_logins
    end
  end

  context "with pluralization" do
    subject { described_class.new("user", true) }
    its(:heading_name) { should == :users }
    it_should_behave_like "a Namer creating names for 'user'"
  end

  context "without pluralization" do
    subject { described_class.new("user", false) }
    its(:heading_name) { should == :user }
    it_should_behave_like "a Namer creating names for 'user'"
  end

  context "with a transformer" do
    let(:transformer) {
      lambda { |n| n.sub(/namespaced_/, '') }
    }
    subject { described_class.new("namespaced_user", true, transformer) }
    its(:heading_name) { should == :users }
    it_should_behave_like "a Namer creating names for 'user'"
  end
end
