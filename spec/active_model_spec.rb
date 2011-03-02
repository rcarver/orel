require 'helper'
require 'test/unit/assertions'
require 'active_model/lint'

describe "Conformance to ActiveModel::Lint" do
  include Test::Unit::Assertions
  include ActiveModel::Lint::Tests

  class ActiveModelNamingCompatible
    include Orel::Object
  end

  # Convert Lint's tests into RSpec examples.
  ActiveModel::Lint::Tests.public_instance_methods.each do |m|
    if m.to_s =~ /^test_/
      example m.gsub('_',' ') do
        send m
      end
    end
  end

  let(:model) { ActiveModelNamingCompatible.new }
end
