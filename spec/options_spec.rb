require 'helper'

describe Orel::Options do

  context "available values" do

    module Group
      def self.orel_options
        {
          :relation_prefix => "rel_prefix",
          :relation_suffix => "rel_suffix",
          :attribute_prefix => "attr_prefix",
          :active_record => :active_record
        }
      end
    end

    subject { described_class.new(Group) }
    its(:relation_prefix) { should == "rel_prefix" }
    its(:relation_suffix) { should == "rel_suffix" }
    its(:attribute_prefix) { should == "attr_prefix" }
    its(:active_record) { should == :active_record }
  end

  context "class/module namespacing" do

    module GroupA
      def self.orel_options
        { :relation_prefix => "group_a_", :group_a => true }
      end
      module LevelOne
        module LevelTwo
          def self.orel_options
            { :relation_prefix => "level2_", :level2 => true }
          end
        end
      end
    end

    context "when multiple points in the hierarchy define options" do

      context "an inner class with its own options" do
        subject { described_class.new(GroupA::LevelOne::LevelTwo) }
        it "merges all keys in the hierarchy" do
          subject.options.keys.should =~ [:relation_prefix, :group_a, :level2]
        end
        it "uses the value of the class" do
          subject.relation_prefix.should == "level2_"
        end
      end

      context "an inner class without its own options" do
        subject { described_class.new(GroupA::LevelOne) }
        it "merges all keys in the hierarchy" do
          subject.options.keys.should =~ [:relation_prefix, :group_a]
        end
        it "uses the nearest parent value" do
          subject.relation_prefix.should == "group_a_"
        end
      end
    end

    context "table_name_prefix and table_name_suffix along with orel_options" do

      module GroupB
        def self.orel_options
          { :relation_prefix => "group_a_", :relation_suffix => "_group_a" }
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
          subject.relation_prefix.should == "group_a_prefix_"
        end
        it "prefers table_name_suffix" do
          subject.relation_suffix.should == "_suffix_group_a"
        end
      end

      context "an inner class with its own values" do
        subject { described_class.new(GroupB::LevelOne) }
        it "uses the local table_name_prefix" do
          subject.relation_prefix.should == "level1_prefix_"
        end
      end
    end

  end
end
