require 'rails_helper'

RSpec.describe PipelineStep, 'NotImplementedError behavior', type: :model do
  let(:pipeline_step) { PipelineStep.new(name: 'Test Step', step_type: 'extract', position: 1) }

  describe 'placeholder extraction methods' do
    describe '#extract_from_file' do
      it 'raises NotImplementedError with descriptive message' do
        expect { pipeline_step.send(:extract_from_file, {}) }
          .to raise_error(NotImplementedError, 'extract_from_file must be implemented by subclasses')
      end
    end

    describe '#extract_from_api' do
      it 'raises NotImplementedError with descriptive message' do
        expect { pipeline_step.send(:extract_from_api, {}) }
          .to raise_error(NotImplementedError, 'extract_from_api must be implemented by subclasses')
      end
    end
  end

  describe 'placeholder loading methods' do
    describe '#load_to_database' do
      it 'raises NotImplementedError with descriptive message' do
        expect { pipeline_step.send(:load_to_database, [], {}) }
          .to raise_error(NotImplementedError, 'load_to_database must be implemented by subclasses')
      end
    end

    describe '#load_to_file' do
      it 'raises NotImplementedError with descriptive message' do
        expect { pipeline_step.send(:load_to_file, [], {}) }
          .to raise_error(NotImplementedError, 'load_to_file must be implemented by subclasses')
      end
    end

    describe '#load_to_api' do
      it 'raises NotImplementedError with descriptive message' do
        expect { pipeline_step.send(:load_to_api, [], {}) }
          .to raise_error(NotImplementedError, 'load_to_api must be implemented by subclasses')
      end
    end
  end
end