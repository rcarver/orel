require 'helper'

describe Orel::SchemaGenerator::Table do

  let(:klass) { UsersAndThings::User }
  let(:namer) { Orel::Relation::Namer.new("name", :pluralize => true) }

  subject { described_class.new(namer, klass.get_heading) }

  its(:name) { should == :users_and_things_users }

  specify "#create_statement"
end
