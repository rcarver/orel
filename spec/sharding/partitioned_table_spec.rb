require 'helper'

describe Orel::Sharding::PartitionedTable do

  let(:klass) { DailyAccumulation }
  let(:connection) { klass.connection }
  let(:partitioner) { klass.shard_partitioner }

  subject { described_class.new(partitioner) }

  def database_tables
    connection.query("show tables").first
  end

  def table_named(name)
    Orel::Table.new(name, klass.get_heading, connection)
  end

  it "inserts into the appropriate partition" do
    subject.insert(:day => "20120101", :thing => "this", :count => 1)

    table_named(:daily_accumulations_201201).row_count.should == 1
    table_named(:daily_accumulations_201201).row_list.should == [
      { :day => "20120101", :thing => "this", :count => 1 }
    ]
  end

  it "upserts into the appropriate partition" do
    subject.insert(:day => "20120101", :thing => "this", :count => 1)

    subject.upsert(
      :insert => { :day => "20120101", :thing => "this", :count => 1 },
      :update => { :values => [:count], :with => :increment }
    )

    table_named(:daily_accumulations_201201).row_count.should == 1
    table_named(:daily_accumulations_201201).row_list.should == [
      { :day => "20120101", :thing => "this", :count => 2 }
    ]
  end

  describe "#query" do
    it "queries against appropriate partitions" do
      subject.insert(:day => "20120101", :thing => "this", :count => 1)
      subject.insert(:day => "20120201", :thing => "that", :count => 2)
      subject.insert(:day => "20120202", :thing => "more", :count => 3)
      subject.insert(:day => "20120203", :thing => "than", :count => 4)

      result = subject.query { |q, table|
        q.project table[:day], table[:thing], table[:count]
        q.where   table[:day].in(["20120101", "20120201", "20120202"])
      }

      result.should =~ [
        { :day => "20120101", :thing => "this", :count => 1 },
        { :day => "20120201", :thing => "that", :count => 2 },
        { :day => "20120202", :thing => "more", :count => 3 }
      ]
    end
    it "queries against all known partitions" do
      subject.insert(:day => "20120101", :thing => "this", :count => 1)
      subject.insert(:day => "20120201", :thing => "that", :count => 1)
      subject.insert(:day => "20120202", :thing => "that", :count => 3)

      result = subject.query { |q, table|
        q.project table[:day], table[:thing], table[:count]
        q.where   table[:count].lt(3)
      }

      result.should =~ [
        { :day => "20120101", :thing => "this", :count => 1 },
        { :day => "20120201", :thing => "that", :count => 1 }
      ]
    end
  end
end
