require 'helper'

describe Orel, ".arel_table" do
  it "always returns the same instance for a heading" do
    a = Orel.arel_table(UsersAndThings::User.get_heading)
    b = Orel.arel_table(UsersAndThings::User.get_heading)
    a.should === b
  end
end
