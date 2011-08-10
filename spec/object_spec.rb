require 'helper'

describe Orel::Object, "validation" do

  describe "an object with no values for its attributes" do
    subject { UsersAndThings::User.new }
    it { should_not be_valid }
  end

  describe "an object with values for its attributes" do
    subject { UsersAndThings::User.new :first_name => "John", :last_name => "Smith", :age => 27 }
    it { should be_valid }
  end

  describe "the errors for an object" do
    subject { UsersAndThings::User.new }
    it "has no information before checking validity" do
      subject.errors.size.should == 0
    end
    it "provides error messages for invalid attributes" do
      subject.should_not be_valid
      subject.errors.size.should > 0
      subject.errors[:first_name].should == ["cannot be blank"]
    end
    it "provides ActiveModel i18n compatible error keys"
  end
end

describe Orel::Object do
  let(:invalid_user_attrs) { {} }
  let(:valid_user_attrs)   { { :first_name => "John", :last_name => "Smith", :age => 33 } }

  let(:invalid_thing_attrs) { {} }
  let(:valid_thing_attrs)   { { :name => "Box", UsersAndThings::User => UsersAndThings::User.create!(valid_user_attrs) } }

  describe "creating new records" do
    context "an invalid record" do
      specify ".create returns an invalid record and does not persist anything" do
        result = UsersAndThings::User.create(invalid_user_attrs)
        result.should be_an_instance_of(UsersAndThings::User)
        result.should_not be_valid
        result.should_not be_persisted
        UsersAndThings::User.table.row_count.should == 0
      end
      specify ".create! raises an error and does not persist anything" do
        expect { UsersAndThings::User.create!(invalid_user_attrs) }.to raise_error(Orel::Object::InvalidRecord)
        UsersAndThings::User.table.row_count.should == 0
      end
    end
    context "a valid record" do
      specify ".create returns a valid and persisted record" do
        result = UsersAndThings::User.create(valid_user_attrs)
        result.should be_an_instance_of(UsersAndThings::User)
        result.should be_valid
        result.should be_persisted
        UsersAndThings::User.table.row_count.should == 1
      end
      specify ".create! returns a valid and persisted record" do
        result = UsersAndThings::User.create(valid_user_attrs)
        result.should be_an_instance_of(UsersAndThings::User)
        result.should be_valid
        result.should be_persisted
        UsersAndThings::User.table.row_count.should == 1
      end
    end
  end

  describe "finding existing records" do
    before { UsersAndThings::User.create!(valid_user_attrs) }

    describe ".find_by_primary_key" do
      it "delegates to the finder" do
        UsersAndThings::User._finder.should_receive(:find_by_key).with(:primary, "John", "Smith").and_return(:yay)
        UsersAndThings::User.find_by_primary_key("John", "Smith").should == :yay
      end
    end
    describe ".find_by_key" do
      it "delegates to the finder" do
        UsersAndThings::User._finder.should_receive(:find_by_key).with(:other, "John", "Smith").and_return(:yay)
        UsersAndThings::User.find_by_key(:other, "John", "Smith").should == :yay
      end
    end
    describe ".find_all" do
      it "delegates to the finder" do
        UsersAndThings::User._finder.should_receive(:find_all).with(:attr1 => "ok", :attr2 => "ko").and_return(:yay)
        UsersAndThings::User.find_all(:attr1 => "ok", :attr2 => "ko").should == :yay
      end
    end
  end

  describe "#save" do
    context "a new invalid record with natural keys" do
      subject { UsersAndThings::User.new(invalid_user_attrs) }
      it "returns false and does not persist the record" do
        subject.save.should be_false
        UsersAndThings::User.table.row_count.should == 0
      end
    end
    context "a new invalid with a surrogate key" do
      subject { UsersAndThings::Thing.new(invalid_thing_attrs) }
      it "returns false and does not persist the record" do
        subject.save.should be_false
        UsersAndThings::Thing.table.row_count.should == 0
      end
    end
    context "a new valid record with natural keys" do
      subject { UsersAndThings::User.new(valid_user_attrs) }
      it "returns true and persists the record" do
        subject.save.should be_true
        UsersAndThings::User.table.row_count.should == 1
      end
    end
    context "a new valid record with a surrogate key" do
      subject { UsersAndThings::Thing.new(valid_thing_attrs) }
      it "returns true and persists the record" do
        subject.save.should be_true
        UsersAndThings::Thing.table.row_count.should == 1
      end
    end
    context "an existing but invalid record" do
      subject { UsersAndThings::User.create!(valid_user_attrs) }
      before do
        subject.first_name = nil
      end
      it "returns false and does not update the record" do
        subject.save.should be_false
        UsersAndThings::User.table.row_count.should == 1
        UsersAndThings::User.table.row_list.first[:first_name].should == "John"
      end
    end
    context "a existing valid record" do
      subject { UsersAndThings::User.create!(valid_user_attrs) }
      before do
        subject.first_name = "Dave"
      end
      it "returns true and persists the record" do
        subject.save.should be_true
        UsersAndThings::User.table.row_count.should == 1
        UsersAndThings::User.table.row_list.first[:first_name].should == "Dave"
      end
    end
  end

  describe "equality" do
    context "a class with natural keys" do
      specify "two unpersisted objects are equal if all their attributes are equal" do
        user1 = UsersAndThings::User.new(valid_user_attrs)
        user2 = UsersAndThings::User.new(valid_user_attrs)
        (user1 == user2).should == true
        (user1.eql?(user2)).should == true
      end
      specify "two unpersisted objects are NOT equal if not all their attributes are equal" do
        user1 = UsersAndThings::User.new(valid_user_attrs)
        user2 = UsersAndThings::User.new(valid_user_attrs.merge(:age => 100))
        (user1 == user2).should == false
        (user1.eql?(user2)).should == false
      end
    end
    context "a class with a surrogate key" do
      specify "two unpersisted objects are equal if all their attributes are equal" do
        thing1 = UsersAndThings::Thing.new(valid_thing_attrs)
        thing2 = UsersAndThings::Thing.new(valid_thing_attrs)
        (thing1 == thing2).should == true
        (thing1.eql?(thing2)).should == true
      end
      specify "a persisted object is not equal to a non-persisted object" do
        thing1 = UsersAndThings::Thing.create!(valid_thing_attrs)
        thing2 = UsersAndThings::Thing.new(valid_thing_attrs)
        (thing1 == thing2).should == false
        (thing1.eql?(thing2)).should == false
      end
    end
  end
end
