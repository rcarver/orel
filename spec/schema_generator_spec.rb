require 'helper'

describe Orel::SchemaGenerator::Table do

  let(:klass) { UsersAndThings::User }
  let(:namer) { Orel::Relation::Namer.new("user", :pluralize => true) }

  subject { described_class.new(klass.get_heading, namer) }

  its(:name) { should == :users }

  specify "#create_statement"
end
