require 'helper'

describe Orel::Relation::Reference do

  it "raises an error if the parent_key is not found" do
    ref = described_class.new(UsersAndThings::User, nil, :foo, UsersAndThings::Thing, nil, :primary)
    expect { ref.parent_key }.to raise_error(
      RuntimeError,
      "users_and_things_users has no key :foo"
    )
  end

  it "raises an error if the child_key is not found" do
    ref = described_class.new(UsersAndThings::User, nil, :primary, UsersAndThings::Thing, nil, :foo)
    expect { ref.child_key }.to raise_error(
      RuntimeError,
      "users_and_things_things has no key :foo"
    )
  end
end
