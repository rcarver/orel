require 'helper'

describe Orel::Table do

  let(:klass) { UsersAndThings::User }
  let(:connection) { klass.connection }

  subject { described_class.new(klass.get_heading, connection) }

  describe "public methods" do

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

    specify "#truncate" do
      subject.insert(:first_name => "John", :last_name => "Smith", :age => 30)
      subject.insert(:first_name => "John", :last_name => "Hancock", :age => 31)
      subject.insert(:first_name => "Mary", :last_name => "Smith", :age => 32)

      subject.truncate!

      subject.row_count.should == 0
    end

    specify "#query" do
      subject.insert(:first_name => "John", :last_name => "Smith", :age => 30)
      subject.insert(:first_name => "Mary", :last_name => "Smith", :age => 32)
      subject.insert(:first_name => "Mary", :last_name => "Doe", :age => 32)

      result = subject.query { |q, table|
        q.project table[:first_name]
        q.where table[:last_name].eq("Smith")
        q.order table[:age].desc
      }

      result.should == [
        { :first_name => "Mary" },
        { :first_name => "John" }
      ]
    end

    specify "#query with batch enumeration" do
      ("a".."g").to_a.reverse.each do |x|
        subject.insert(:first_name => x, :last_name => "Doe", :age => 30)
      end

      results = subject.query { |q, table|
        q.project table[:first_name]
        q.where table[:first_name].gteq("b")
        q.query_batches :size => 2, :group => true
      }
      expect(results).to be_instance_of(Enumerator)
      expect(results.to_a).to eql([
        [
          { :first_name => "b" },
          { :first_name => "c" }
        ],
        [
          { :first_name => "d" },
          { :first_name => "e" }
        ],
        [
          { :first_name => "f" },
          { :first_name => "g" }
        ]
      ])
    end

    describe "#as" do
      it "returns an Arel table" do
        subject.as.should be_an_instance_of(Arel::Table)
        subject.as.name.should == "users_and_things_users"
      end
      it "may be aliased" do
        subject.as("my_users").name.should == "my_users"
      end
      it "yields the table if a block is given" do
        table = nil
        result = subject.as { |t| table = t }
        table.should be_an_instance_of(Arel::Table)
        result.should be_nil
      end
    end
  end

  describe "sql statements" do

    specify "#insert_statement" do
      sql = subject.insert_statement(:first_name => "John", :last_name => "Smith", :age => 30)
      sql.should == %{INSERT INTO `users_and_things_users` (`age`, `first_name`, `last_name`) VALUES (30, 'John', 'Smith')}
    end

    specify "#upsert_statement with :increment" do
      sql = subject.upsert_statement(
        :insert => { :first_name => "John", :last_name => "Smith", :age => 30 },
        :update => { :values => [:age], :with => :increment }
      )
      sql.should == %{INSERT INTO `users_and_things_users` (`age`, `first_name`, `last_name`) VALUES (30, 'John', 'Smith') ON DUPLICATE KEY UPDATE age=age+VALUES(age)}
    end

    specify "#upsert_statement with :increment and multiple updates" do
      sql = subject.upsert_statement(
        :insert => { :first_name => "John", :last_name => "Smith", :age => 30 },
        :update => { :values => [:age, :last_name], :with => :increment }
      )
      sql.should == %{INSERT INTO `users_and_things_users` (`age`, `first_name`, `last_name`) VALUES (30, 'John', 'Smith') ON DUPLICATE KEY UPDATE age=age+VALUES(age),last_name=last_name+VALUES(last_name)}
    end

    specify "#upsert_statement with :replace and multiple updates" do
      sql = subject.upsert_statement(
        :insert => { :first_name => "John", :last_name => "Smith", :age => 30 },
        :update => { :values => [:age, :last_name], :with => :replace }
      )
      sql.should == %{INSERT INTO `users_and_things_users` (`age`, `first_name`, `last_name`) VALUES (30, 'John', 'Smith') ON DUPLICATE KEY UPDATE age=VALUES(age),last_name=VALUES(last_name)}
    end

    specify "#update_statement" do
      sql = subject.update_statement(
        :find => { :last_name => "Smith" },
        :set  => { :first_name => "John" }
      )
      sql.should == %{UPDATE `users_and_things_users` SET `first_name` = 'John' WHERE `users_and_things_users`.`last_name` = 'Smith'}
    end

    specify "#delete_statement" do
      sql = subject.delete_statement(:first_name => "John")
      sql.should == %{DELETE FROM `users_and_things_users` WHERE `users_and_things_users`.`first_name` = 'John'}
    end
  end

end

