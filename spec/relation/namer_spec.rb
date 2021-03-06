require 'helper'

describe Orel::Relation::Namer do

  module NamerTestModules
    module Base
      module Thing; end
    end
    module BaseWithPrefix
      def self.orel_options
        {
          :prefix => "prefixed_"
        }
      end
      module Thing; end
    end
  end

  describe ".for_class" do
    def build(klass)
      options = Orel::Options.new(klass)
      described_class.for_class(klass, options)
    end
    it "turns a top level class into a namer" do
      namer = build(Object)
      namer.heading_name.should == :objects
    end
    it "turns a namespaced class into a namer" do
      namer = build(NamerTestModules::Base::Thing)
      namer.heading_name.should == :things
    end
    it "uses options" do
      namer = build(NamerTestModules::BaseWithPrefix::Thing)
      namer.heading_name.should == :prefixed_things
    end
  end

  context "without a prefix" do
    let(:options) { {} }

    shared_examples_for "a Namer creating names for 'user'" do
      specify "a foreign key name" do
        subject.foreign_attribute_name(:name).should == :name
      end
      specify "a foreign key name for the attribute 'id'" do
        subject.foreign_attribute_name(:id).should == :user_id
      end
      specify "a unique key name" do
        subject.unique_key_name([:first_name, :last_name]).should == ('u_fn_ln_' + Digest::MD5.hexdigest('first_name::last_name')).to_sym
      end
      specify "a foreign key constraint name" do
        subject.foreign_key_constraint_name(:things, [:first_name, :last_name]).should == ('u_t_fn_ln_' + Digest::MD5.hexdigest('first_name::last_name')).to_sym
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
      subject { described_class.new("user", options.merge(:pluralize => true)) }
      its(:heading_name) { should == :users }
      it_should_behave_like "a Namer creating names for 'user'"
    end

    context "without pluralization" do
      subject { described_class.new("user", options.merge(:pluralize => false)) }
      its(:heading_name) { should == :user }
      it_should_behave_like "a Namer creating names for 'user'"
    end
  end

  context "with a relation prefix" do
    let(:options) { { :prefix => 'project_' } }

    shared_examples_for "a Namer creating names for 'user' prefixed with 'project_'" do
      specify "a foreign key name" do
        subject.foreign_attribute_name(:name).should == :name
      end
      specify "a foreign key name for the attribute 'id'" do
        subject.foreign_attribute_name(:id).should == :user_id
      end
      specify "a unique key name" do
        subject.unique_key_name([:first_name, :last_name]).should == ('pu_fn_ln_' + Digest::MD5.hexdigest('first_name::last_name')).to_sym
      end
      specify "a foreign key constraint name" do
        subject.foreign_key_constraint_name(:things, [:first_name, :last_name]).should == ('pu_t_fn_ln_' + Digest::MD5.hexdigest('first_name::last_name')).to_sym
      end
      specify "the namer for a singular child" do
        namer = subject.for_child(:status)
        namer.heading_name.should == :project_user_status
      end
      specify "the namer for a plural child" do
        namer = subject.for_child(:logins)
        namer.heading_name.should == :project_user_logins
      end
    end

    context "with pluralization" do
      subject { described_class.new("user", options.merge(:pluralize => true)) }
      its(:heading_name) { should == :project_users }
      it_should_behave_like "a Namer creating names for 'user' prefixed with 'project_'"
    end

    context "without pluralization" do
      subject { described_class.new("user", options.merge(:pluralize => false)) }
      its(:heading_name) { should == :project_user }
      it_should_behave_like "a Namer creating names for 'user' prefixed with 'project_'"
    end
  end
end
