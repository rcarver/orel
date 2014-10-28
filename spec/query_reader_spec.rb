require 'helper'

describe Orel::QueryReader do

  let(:fake_options) { instance_double(Orel::QueryReader::Options) }
  let(:fake_reader) { instance_double(Orel::QueryReader::Reader) }

  let(:fake_heading) { double("header") }
  let(:fake_manager) { double("manager") }
  let(:fake_table) { {} }

  let(:query_reader) {
    Orel::QueryReader.new(
      fake_options,
      fake_reader,
      fake_heading,
      fake_manager,
      fake_table
    )
  }

  describe "#read" do

    describe "without batching" do

      before do
        allow(fake_options).to receive(:batch_size) { nil }
        allow(fake_options).to receive(:description) { "Super" }

        expect(fake_reader).to receive(:read).with("Super") { [1, 2, 3] }
      end

      it "reads everything from the reader, returning an array" do
        results = query_reader.read
        expect(results).to be_instance_of(Array)
        expect(results).to eql([1, 2, 3])
      end
    end

    describe "with batching" do

      before do
        allow(fake_options).to receive(:batch_size) { 4 }
        allow(fake_options).to receive(:description) { "Super" }

        expect(fake_reader).to receive(:read).with("Super (batch rows: 0-3)") { [1, 2, 3, 4] }
        expect(fake_reader).to receive(:read).with("Super (batch rows: 4-7)") { [5, 6, 7, 8] }
        expect(fake_reader).to receive(:read).with("Super (batch rows: 8-11)") { [9] }

        expect(fake_manager).to receive(:skip).with(0).ordered
        expect(fake_manager).to receive(:skip).with(4).ordered
        expect(fake_manager).to receive(:skip).with(8).ordered
        expect(fake_manager).to receive(:take).with(4).exactly(3).times
      end

      describe "no ordering, no grouping" do

        before do
          allow(fake_options).to receive(:batch_group) { false }
          allow(fake_options).to receive(:batch_order) { false }
        end

        it "reads everything from the reader, enumerating each object" do
          results = query_reader.read
          expect(results).to be_instance_of(Enumerator)
          expect(results.to_a).to eql([1, 2, 3, 4, 5, 6, 7, 8, 9])
        end
      end

      describe "with grouping" do

        before do
          allow(fake_options).to receive(:batch_group) { true }
          allow(fake_options).to receive(:batch_order) { false }
        end

        it "reads everything from the reader, enumerating groups" do
          results = query_reader.read
          expect(results).to be_instance_of(Enumerator)
          expect(results.to_a).to eql([
            [1, 2, 3, 4],
            [5, 6, 7, 8],
            [9]
          ])
        end
      end

      describe "with ordering" do

        before do
          allow(fake_options).to receive(:batch_group) { false }
          allow(fake_options).to receive(:batch_order) { true }
        end

        it "defines order, then reads from the reader" do
          fake_table.update(
            "a" => "ta",
            "b" => "tb"
          )

          allow(fake_heading).to receive(:attributes) {
            [
              double(:name => "a"),
              double(:name => "b")
            ]
          }
          allow(fake_manager).to receive(:order).with("ta")
          allow(fake_manager).to receive(:order).with("tb")

          results = query_reader.read
          expect(results).to be_instance_of(Enumerator)
          expect(results.to_a).to eql([1, 2, 3, 4, 5, 6, 7, 8, 9])
        end
      end
    end

    describe "batching edge cases" do

      specify "when results do not divide evenly into batches" do

        allow(fake_options).to receive(:batch_size) { 2 }
        allow(fake_options).to receive(:batch_group) { true }
        allow(fake_options).to receive(:batch_order) { false }
        allow(fake_options).to receive(:description) { "Super" }

        expect(fake_reader).to receive(:read).with("Super (batch rows: 0-1)") { [1, 2] }
        expect(fake_reader).to receive(:read).with("Super (batch rows: 2-3)") { [3] }

        expect(fake_manager).to receive(:skip).with(0).ordered
        expect(fake_manager).to receive(:skip).with(2).ordered
        expect(fake_manager).to receive(:take).with(2).exactly(2).times

        results = query_reader.read
        expect(results).to be_instance_of(Enumerator)
        expect(results.to_a).to eql([[1, 2], [3]])
      end

      specify "when results divide evenly into batches" do

        allow(fake_options).to receive(:batch_size) { 2 }
        allow(fake_options).to receive(:batch_group) { true }
        allow(fake_options).to receive(:batch_order) { false }
        allow(fake_options).to receive(:description) { "Super" }

        expect(fake_reader).to receive(:read).with("Super (batch rows: 0-1)") { [1, 2] }
        expect(fake_reader).to receive(:read).with("Super (batch rows: 2-3)") { [3, 4] }
        expect(fake_reader).to receive(:read).with("Super (batch rows: 4-5)") { [] }

        expect(fake_manager).to receive(:skip).with(0).ordered
        expect(fake_manager).to receive(:skip).with(2).ordered
        expect(fake_manager).to receive(:skip).with(4).ordered
        expect(fake_manager).to receive(:take).with(2).exactly(3).times

        results = query_reader.read
        expect(results).to be_instance_of(Enumerator)
        expect(results.to_a).to eql([[1, 2], [3, 4]])
      end
    end
  end
end
