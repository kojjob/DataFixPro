require 'rails_helper'

RSpec.describe 'PipelineExecutionEngine#calculate_non_materializing_count', type: :service do
  # Create a minimal test instance without dependencies
  let(:test_pipeline) { double('Pipeline', id: 1) }
  let(:test_engine) { PipelineExecutionEngine.new(test_pipeline) }

  describe '#calculate_non_materializing_count' do
    context 'with nil input' do
      it 'returns 0' do
        expect(test_engine.send(:calculate_non_materializing_count, nil)).to eq(0)
      end
    end

    context 'with ActiveRecord::Relation' do
      it 'calls count on the relation without loading records' do
        relation = double('ActiveRecord::Relation')
        allow(relation).to receive(:is_a?).and_call_original
        allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        expect(relation).to receive(:count).and_return(42)
        expect(relation).not_to receive(:to_a)
        expect(relation).not_to receive(:load)

        expect(test_engine.send(:calculate_non_materializing_count, relation)).to eq(42)
      end
    end

    context 'with Array' do
      it 'uses size method instead of count' do
        array = [1, 2, 3, 4, 5]
        expect(array).not_to receive(:count)

        expect(test_engine.send(:calculate_non_materializing_count, array)).to eq(5)
      end

      it 'handles large arrays efficiently' do
        large_array = Array.new(100_000) { |i| i }

        # Should use size, not count (which might iterate)
        expect(large_array).not_to receive(:count)

        result = test_engine.send(:calculate_non_materializing_count, large_array)
        expect(result).to eq(100_000)
      end
    end

    context 'with Hash' do
      it 'uses size method' do
        hash = { a: 1, b: 2, c: 3 }
        expect(hash).not_to receive(:count)

        expect(test_engine.send(:calculate_non_materializing_count, hash)).to eq(3)
      end
    end

    context 'with object responding to count' do
      it 'calls count method' do
        countable = double('Countable')
        allow(countable).to receive(:is_a?).and_return(false)
        expect(countable).to receive(:respond_to?).with(:count).and_return(true)
        expect(countable).to receive(:count).and_return(10)

        expect(test_engine.send(:calculate_non_materializing_count, countable)).to eq(10)
      end
    end

    context 'with object responding to size but not count' do
      it 'calls size method' do
        sizable = double('Sizable')
        allow(sizable).to receive(:is_a?).and_return(false)
        expect(sizable).to receive(:respond_to?).with(:count).and_return(false)
        expect(sizable).to receive(:respond_to?).with(:size).and_return(true)
        expect(sizable).to receive(:size).and_return(8)

        expect(test_engine.send(:calculate_non_materializing_count, sizable)).to eq(8)
      end
    end

    context 'with object responding to length but not count or size' do
      it 'calls length method' do
        lengthy = double('Lengthy')
        allow(lengthy).to receive(:is_a?).and_return(false)
        expect(lengthy).to receive(:respond_to?).with(:count).and_return(false)
        expect(lengthy).to receive(:respond_to?).with(:size).and_return(false)
        expect(lengthy).to receive(:respond_to?).with(:length).and_return(true)
        expect(lengthy).to receive(:length).and_return(6)

        expect(test_engine.send(:calculate_non_materializing_count, lengthy)).to eq(6)
      end
    end

    context 'with Enumerable that does not respond to count, size, or length' do
      it 'iterates to count elements' do
        # Create an enumerable that doesn't have count/size/length
        enumerable = (1..5).each
        allow(enumerable).to receive(:respond_to?).with(:count).and_return(false)
        allow(enumerable).to receive(:respond_to?).with(:size).and_return(false)
        allow(enumerable).to receive(:respond_to?).with(:length).and_return(false)
        allow(enumerable).to receive(:is_a?).with(Enumerable).and_return(true)
        allow(enumerable).to receive(:is_a?).with(anything).and_call_original

        expect(test_engine.send(:calculate_non_materializing_count, enumerable)).to eq(5)
      end
    end

    context 'with unknown object type' do
      it 'falls back to Array conversion with warning' do
        unknown = double('Unknown')
        allow(unknown).to receive(:is_a?).and_return(false)
        allow(unknown).to receive(:respond_to?).with(:count).and_return(false)
        allow(unknown).to receive(:respond_to?).with(:size).and_return(false)
        allow(unknown).to receive(:respond_to?).with(:length).and_return(false)
        allow(unknown).to receive(:class).and_return('UnknownClass')

        # Mock the logger
        logger = double('Logger')
        allow(Rails).to receive(:logger).and_return(logger)
        expect(logger).to receive(:warn).with(/Unknown data type for counting: UnknownClass/)
        expect(logger).to receive(:info).at_least(:once)

        # Allow Array conversion
        allow(Array).to receive(:call).with(unknown).and_return([1, 2])

        expect(test_engine.send(:calculate_non_materializing_count, unknown)).to eq(2)
      end
    end
  end
end