require 'helper'

describe Orel::QueryBatches do

  let(:helper) { Class.new }

  before(:each) do
    helper.extend Orel::QueryBatches
  end

  describe "#query_batches" do

    it "has defaults before being called" do
      expect(helper.batch_size).to be_nil
      expect(helper.batch_group).to be_nil
      expect(helper.batch_order).to be_nil
    end

    it "has defaults when called" do
      helper.query_batches
      expect(helper.batch_size).to eql(1000)
      expect(helper.batch_group).to eql(false)
      expect(helper.batch_order).to eql(true)
    end

    it "sets size" do
      helper.query_batches :size => 40
      expect(helper.batch_size).to eql(40)
    end

    it "sets group" do
      helper.query_batches :group => true
      expect(helper.batch_group).to eql(true)
    end

    it "sets order" do
      helper.query_batches :order => false
      expect(helper.batch_order).to eql(false)
    end

    it "raises an error if you try to set something else" do
      expect { helper.query_batches :foo => false }.to raise_error(ArgumentError)
    end
  end
end

