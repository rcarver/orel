require 'helper'

describe Orel::Options do

  context "available values" do

    module Group
      def self.orel_options
        {
          :prefix => "rel_prefix",
          :suffix => "rel_suffix",
          :pluralize => false,
          :active_record => :active_record
        }
      end
    end

    describe "by default" do
      subject { described_class.new(Object) }
      its(:prefix) { should be_nil }
      its(:suffix) { should be_nil }
      its(:pluralize) { should be_true }
      its(:active_record) { should == Orel::AR }
    end

    describe "values set" do
      subject { described_class.new(Group) }
      its(:prefix) { should == "rel_prefix" }
      its(:suffix) { should == "rel_suffix" }
      its(:pluralize) { should be_false }
      its(:active_record) { should == :active_record }
    end
  end

  context "class/module namespacing" do

    module GroupA
      def self.orel_options
        { :prefix => "group_a_", :group_a => true }
      end
      module LevelOne
        module LevelTwo
          def self.orel_options
            { :prefix => "level2_", :level2 => true }
          end
        end
      end
    end

    context "when multiple points in the hierarchy define options" do

      context "an inner class with its own options" do
        subject { described_class.new(GroupA::LevelOne::LevelTwo) }
        it "merges all keys in the hierarchy" do
          subject.options.keys.should =~ [:prefix, :group_a, :level2]
        end
        it "uses the value of the class" do
          subject.prefix.should == "level2_"
        end
      end

      context "an inner class without its own options" do
        subject { described_class.new(GroupA::LevelOne) }
        it "merges all keys in the hierarchy" do
          subject.options.keys.should =~ [:prefix, :group_a]
        end
        it "uses the nearest parent value" do
          subject.prefix.should == "group_a_"
        end
      end
    end

    context "table_name_prefix and table_name_suffix along with orel_options" do

      module GroupB
        def self.orel_options
          { :prefix => "group_a_", :suffix => "_group_a" }
        end
        def self.table_name_prefix
          "group_a_prefix_"
        end
        def self.table_name_suffix
          "_suffix_group_a"
        end
        module LevelOne
          def self.table_name_prefix
            "level1_prefix_"
          end
        end
      end

      context "within the same class" do
        subject { described_class.new(GroupB) }
        it "prefers table_name_prefix" do
          subject.prefix.should == "group_a_prefix_"
        end
        it "prefers table_name_suffix" do
          subject.suffix.should == "_suffix_group_a"
        end
      end

      context "an inner class with its own values" do
        subject { described_class.new(GroupB::LevelOne) }
        it "uses the local table_name_prefix" do
          subject.prefix.should == "level1_prefix_"
        end
      end
    end

  end
end
