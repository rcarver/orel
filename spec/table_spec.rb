require 'helper'

describe Orel::Table do

  let(:klass) { UsersAndThings::User }
  let(:namer) { Orel::Relation::Namer.for_class(klass) }

  subject { described_class.new(namer, klass.get_heading) }

  specify "#row_count" do
    subject.row_count.should == 0
  end

  specify "#row_list" do
    subject.row_list.should be_empty
  end

  specify "#insert" do
    subject.insert(:first_name => "John", :last_name => "Smith", :age => 30)

    subject.row_count.should == 1
    subject.row_list.should == [
      { :first_name => "John", :last_name => "Smith", :age => 30 }
    ]
  end

  specify "#upsert" do
    subject.insert(:first_name => "John", :last_name => "Smith", :age => 30)

    subject.upsert(
      :insert => { :first_name => "John", :last_name => "Smith", :age => 1 },
      :update => { :values => [:age], :with => :increment }
    )

    subject.row_count.should == 1
    subject.row_list.should == [
      { :first_name => "John", :last_name => "Smith", :age => 31 }
    ]
  end

  specify "#update" do
    subject.insert(:first_name => "John", :last_name => "Smith", :age => 30)
    subject.insert(:first_name => "Mary", :last_name => "Smith", :age => 32)

    subject.update(
      :find => { :first_name => "John" },
      :set  => { :last_name => "Doe" }
    )

    subject.row_count.should == 2
    subject.row_list.should == [
      { :first_name => "John", :last_name => "Doe", :age => 30 },
      { :first_name => "Mary", :last_name => "Smith", :age => 32 }
    ]
  end

  specify "#delete" do
    subject.insert(:first_name => "John", :last_name => "Smith", :age => 30)
    subject.insert(:first_name => "John", :last_name => "Hancock", :age => 31)
    subject.insert(:first_name => "Mary", :last_name => "Smith", :age => 32)

    subject.delete(:first_name => "John")

    subject.row_count.should == 1
    subject.row_list.should == [
      { :first_name => "Mary", :last_name => "Smith", :age => 32 }
    ]
  end
end
