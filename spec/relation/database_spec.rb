require 'helper'

describe Orel::Relation::Database do
  describe "#relation_name" do
    it "turns a class name into a relation name" do
      db = Orel::Relation::Database.new(Object)
      db.relation_name.should == "object"
    end
    it "can create sub-relation names" do
      db = Orel::Relation::Database.new(Object)
      db.relation_name(:thing).should == "object_thing"
    end
    it "handles namespaced classes" do
      db = Orel::Relation::Database.new(Orel::Relation)
      db.relation_name.should == "orel_relation"
    end
  end
end
