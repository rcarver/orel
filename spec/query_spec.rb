require 'helper'

describe Orel::Query do

  before do
    @user1 = UsersAndThings::User.create!(:first_name => "John", :last_name => "Doe", :age => 30)
    @thing1 = UsersAndThings::Thing.create!(UsersAndThings::User => @user1, :name => "box")

    @user2 = UsersAndThings::User.create!(:first_name => "John", :last_name => "Smith", :age => 30)
    @thing2 = UsersAndThings::Thing.create!(UsersAndThings::User => @user2, :name => "table")
    @user2[:ips] << { :ip => "127.0.0.1" }
    @user2[:ips] << { :ip => "192.168.0.1" }
    @user2.save
  end

  let(:user_query) { Orel::Query.new(UsersAndThings::User, UsersAndThings::User.get_heading) }
  let(:thing_query) { Orel::Query.new(UsersAndThings::Thing, UsersAndThings::Thing.get_heading) }

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
    pending
    user_query.query[0].should be_locked_for_query
  end

  specify "a query that limits results using a condition" do
    results = user_query.query { |q, user|
      q.where user[:last_name].eq("Doe")
    }
    results.should == [@user1]
  end

  context "1:M simple association" do
    specify "a query that joins a M:1 simple association" do
      results = user_query.query { |q, user|
        q.join  user[:ips]
        q.where user[:last_name].eq("Smith")
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
  end

end
