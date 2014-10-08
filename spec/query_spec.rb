require 'helper'

describe Orel::Query, "#query" do

  before do
    @user1 = UsersAndThings::User.create!(:first_name => "John", :last_name => "Doe", :age => 30)
    @thing1 = UsersAndThings::Thing.create!(UsersAndThings::User => @user1, :name => "box")

    @user2 = UsersAndThings::User.create!(:first_name => "John", :last_name => "Smith", :age => 33)
    @thing2 = UsersAndThings::Thing.create!(UsersAndThings::User => @user2, :name => "table")
    @user2[:ips] << { :ip => "127.0.0.1" }
    @user2[:ips] << { :ip => "192.168.0.1" }
    @user2.save
  end

  let(:user_query)  { Orel::Query.new(UsersAndThings::User) }
  let(:thing_query) { Orel::Query.new(UsersAndThings::Thing) }

  specify "a query that returns everything" do
    results = user_query.query
    results.size.should == 2
    results.should =~ [@user1, @user2]
  end

  specify "a query returns persisted objects" do
    user_query.query[0].should be_persisted
  end

  specify "a query returns objects that are readonly" do
    user_query.query[0].should be_readonly
  end

  specify "a query returns objects that are locked for query" do
    user_query.query[0].should be_locked_for_query
  end

  specify "a query may allow objects to be further queried" do
    results = user_query.query { |q, user|
      q.unlock_for_query!
    }
    results[0].should_not be_locked_for_query
  end

  specify "a query that limits results using a condition" do
    results = user_query.query { |q, user|
      q.where user[:last_name].eq("Doe")
    }
    results.should == [@user1]
  end

  context "1:M simple association" do
    specify "a query that projects a M:1 simple association" do
      results = user_query.query { |q, user|
        q.project user[:ips]
      }
      results.first.should == @user2
      results.first[:ips].map { |r| r.to_hash }.should == [{ :ip => "127.0.0.1" }, { :ip => "192.168.0.1" }]
    end
    specify "a query that specifies a condition on a simple assoication's attributes" do
      results = user_query.query { |q, user|
        q.where user[:ips][:ip].eq("127.0.0.1")
      }
      results.should == [@user2]
    end
  end

  context "M:1 reference" do
    specify "a query that projects a M:1 reference" do
      results = thing_query.query { |q, thing|
        q.project thing[UsersAndThings::User]
      }
      hash = Hash[*results.map { |r| [r, r[UsersAndThings::User]] }.flatten]
      hash.should == {
        @thing1 => @user1,
        @thing2 => @user2
      }
    end
    specify "a query that specifies a condition using an object" do
      results = thing_query.query { |q, thing|
        q.where thing[UsersAndThings::User].eq(@user1)
      }
      results.should == [@thing1]
    end
    specify "a query that specifies a condition using the value of an attribute" do
      results = thing_query.query { |q, thing|
        q.where thing[UsersAndThings::User][:last_name].eq("Smith")
      }
      results.should == [@thing2]
    end
  end

  context "1:M reference" do
    specify "a query that specifies a condition using an object" do
      results = user_query.query { |q, user|
        q.where user[UsersAndThings::Thing].eq(@thing1)
      }
      results.should == [@user1]
    end
    specify "a query that specifies a condition using the value of an attribute" do
      results = user_query.query { |q, user|
        q.where user[UsersAndThings::Thing][:name].eq("table")
      }
      results.should == [@user2]
    end
  end

  context "complex queries" do
    specify "a query that specifies two conditions on a join" do
      results = thing_query.query { |q, thing|
        q.where thing[UsersAndThings::User][:first_name].eq("John")
        q.where thing[UsersAndThings::User][:last_name].eq("Smith")
      }
      results.should == [@thing2]
    end
    specify "a query that specifies a gt comparison" do
      results = user_query.query { |q, user|
        q.where user[:age].gt(31)
      }
      results.should == [@user2]
    end
    specify "a query that specifies a gt comparison on a join" do
      results = thing_query.query { |q, thing|
        q.where thing[UsersAndThings::User][:age].gt(31)
      }
      results.should == [@thing2]
    end
  end

end

describe Orel::Query, "#query with batch enumeration" do

  before do
    ("a".."g").to_a.reverse.each do |x|
      UsersAndThings::User.create!(:first_name => x, :last_name => "Doe", :age => 30)
    end
  end

  let(:user_query)  { Orel::Query.new(UsersAndThings::User) }

  it "queries batches, yielding batches" do
    results = user_query.query(:batch_size => 2, :group => true) { |q, user|
      # nothing
    }
    expect(results).to be_instance_of(Enumerator)
    expect_batches = [
      ["a", "b"],
      ["c", "d"],
      ["e", "f"],
      ["g"]
    ]
    actual_batches = 0
    results.each.with_index do |batch, i|
      expect(batch.size).to eql(expect_batches[i].size)
      actual_batches += 1
      batch.each.with_index do |u, j|
        expect(u.first_name).to eql(expect_batches[i][j])
      end
    end
    expect(actual_batches).to eq(expect_batches.size)
  end

  it "queries batches, yielding each object" do
    results = user_query.query(:batch_size => 2) { |q, user|
      # nothing
    }
    expect(results).to be_instance_of(Enumerator)
    expect_users = [
      "a",
      "b",
      "c",
      "d",
      "e",
      "f",
      "g"
    ]
    actual_users = 0
    results.each.with_index do |u, i|
      actual_users += 1
      expect(u.first_name).to eql(expect_users[i])
    end
    expect(actual_users).to eq(expect_users.size)
  end

  it "queries batches with conditions" do
    results = user_query.query(:batch_size => 2, :group => true) { |q, user|
      q.where user[:first_name].lteq("d")
      q.where user[:first_name].gteq("b")
    }
    expect(results).to be_instance_of(Enumerator)
    expect_batches = [
      ["b", "c"],
      ["d"]
    ]
    actual_batches = 0
    results.each.with_index do |batch, i|
      expect(batch.size).to eql(expect_batches[i].size)
      actual_batches += 1
      batch.each.with_index do |u, j|
        expect(u.first_name).to eql(expect_batches[i][j])
      end
    end
    expect(actual_batches).to eq(expect_batches.size)
  end

  it "allows a description enumerates in batches with offset" do
    results = user_query.query("testing", :batch_size => 2) { |q, user|
      # nothing
    }
    results.each do |u|
      # nothing
    end
    expect(results).to be_instance_of(Enumerator)
  end
end
