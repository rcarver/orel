require 'helper'

describe Orel::Relation::Namer do

  context "with a top level class" do
    subject { described_class.new(Object) }
    it "turns a class name into a base name" do
      subject.base_name.should == "objects"
    end
    it "turns a symbol into a child name" do
      subject.child_name(:thing).should == "object_thing"
      subject.child_name(:things).should == "object_things"
    end
  end

  context "with a namespaced classs" do
    subject { described_class.new(Orel::Relation) }
    it "turns a class name into a base name" do
      subject.base_name.should == "orel_relations"
    end
    it "turns a symbol into a child name" do
      subject.child_name(:thing).should == "orel_relation_thing"
      subject.child_name(:things).should == "orel_relation_things"
    end
  end

end
