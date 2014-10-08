require 'helper'

describe Orel::Connection do

  let(:active_record_connection) { stub("ar connection") }
  let(:active_record) { double("AR", :connection => active_record_connection) }
  subject { Orel::Connection.new(active_record) }

  describe ".arel_table" do
    it "always returns the same instance for a heading" do
      a = subject.arel_table(UsersAndThings::User.get_heading)
      b = subject.arel_table(UsersAndThings::User.get_heading)
      c = subject.arel_table(UsersAndThings::User.get_heading(:ips))
      a.should === b
      b.should_not === c
    end
  end
end
