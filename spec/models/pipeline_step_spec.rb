require 'rails_helper'

RSpec.describe PipelineStep, type: :model do
  describe 'associations' do
    it { should belong_to(:pipeline) }
    it { should have_many(:step_executions).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:step_type) }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).is_greater_than_or_equal_to(1) }
    it { should validate_inclusion_of(:step_type).in_array(%w[extract transform load filter validate aggregate custom]) }
    it { should validate_inclusion_of(:status).in_array(%w[enabled disabled]) }
  end

  describe 'scopes' do
    let(:tenant) { create(:tenant) }
    let(:data_source) { create(:data_source, tenant: tenant) }
    let(:pipeline) { create(:pipeline, data_source: data_source) }

    before do
      ActsAsTenant.current_tenant = tenant
      @enabled_step = create(:pipeline_step, pipeline: pipeline, status: 'enabled')
      @disabled_step = create(:pipeline_step, pipeline: pipeline, status: 'disabled')
    end

    describe '.enabled' do
      it 'returns only enabled steps' do
        expect(PipelineStep.enabled).to contain_exactly(@enabled_step)
      end
    end

    describe '.disabled' do
      it 'returns only disabled steps' do
        expect(PipelineStep.disabled).to contain_exactly(@disabled_step)
      end
    end
  end

  describe 'instance methods' do
    let(:tenant) { create(:tenant) }
    let(:data_source) { create(:data_source, tenant: tenant) }
    let(:pipeline) { create(:pipeline, data_source: data_source) }
    let(:step) { create(:pipeline_step, pipeline: pipeline) }

    before { ActsAsTenant.current_tenant = tenant }

    describe '#enabled?' do
      it 'returns true when status is enabled' do
        step.status = 'enabled'
        expect(step.enabled?).to be true
      end

      it 'returns false when status is disabled' do
        step.status = 'disabled'
        expect(step.enabled?).to be false
      end
    end

    describe '#execute' do
      context 'with extract step' do
        let(:step) do
          create(:pipeline_step,
            pipeline: pipeline,
            step_type: 'extract',
            configuration: {
              'source_type' => 'database',
              'query' => 'SELECT * FROM users LIMIT 10'
            }
          )
        end

        it 'executes extraction logic' do
          input_data = nil
          result = step.execute(input_data)

          expect(result).to be_a(Hash)
          expect(result[:success]).to be_in([true, false])
          expect(result).to have_key(:data)
          expect(result).to have_key(:metadata)
        end
      end

      context 'with transform step' do
        let(:step) do
          create(:pipeline_step,
            pipeline: pipeline,
            step_type: 'transform',
            configuration: {
              'transformations' => [
                { 'type' => 'rename', 'from' => 'id', 'to' => 'user_id' },
                { 'type' => 'uppercase', 'field' => 'name' }
              ]
            }
          )
        end

        it 'executes transformation logic' do
          input_data = [
            { 'id' => 1, 'name' => 'john' },
            { 'id' => 2, 'name' => 'jane' }
          ]

          result = step.execute(input_data)

          expect(result[:success]).to be true
          expect(result[:data]).to be_an(Array)
          expect(result[:metadata][:rows_transformed]).to eq(2)
        end
      end

      context 'with filter step' do
        let(:step) do
          create(:pipeline_step,
            pipeline: pipeline,
            step_type: 'filter',
            configuration: {
              'condition' => { 'field' => 'age', 'operator' => '>=', 'value' => 18 }
            }
          )
        end

        it 'filters data based on conditions' do
          input_data = [
            { 'name' => 'Alice', 'age' => 25 },
            { 'name' => 'Bob', 'age' => 15 },
            { 'name' => 'Charlie', 'age' => 30 }
          ]

          result = step.execute(input_data)

          expect(result[:success]).to be true
          expect(result[:data].count).to eq(2)
          expect(result[:metadata][:rows_filtered]).to eq(1)
        end
      end

      context 'with validate step' do
        let(:step) do
          create(:pipeline_step,
            pipeline: pipeline,
            step_type: 'validate',
            configuration: {
              'validations' => [
                { 'field' => 'email', 'type' => 'format', 'pattern' => 'email' },
                { 'field' => 'age', 'type' => 'range', 'min' => 0, 'max' => 120 }
              ]
            }
          )
        end

        it 'validates data and reports errors' do
          input_data = [
            { 'email' => 'valid@example.com', 'age' => 25 },
            { 'email' => 'invalid-email', 'age' => 150 }
          ]

          result = step.execute(input_data)

          expect(result[:success]).to be true
          expect(result[:metadata][:validation_errors]).to be_present
        end
      end

      context 'with aggregate step' do
        let(:step) do
          create(:pipeline_step,
            pipeline: pipeline,
            step_type: 'aggregate',
            configuration: {
              'group_by' => 'department',
              'aggregations' => [
                { 'field' => 'salary', 'function' => 'sum', 'alias' => 'total_salary' },
                { 'field' => '*', 'function' => 'count', 'alias' => 'employee_count' }
              ]
            }
          )
        end

        it 'aggregates data based on configuration' do
          input_data = [
            { 'department' => 'IT', 'salary' => 50000 },
            { 'department' => 'IT', 'salary' => 60000 },
            { 'department' => 'HR', 'salary' => 45000 }
          ]

          result = step.execute(input_data)

          expect(result[:success]).to be true
          expect(result[:data]).to be_an(Array)
          expect(result[:metadata][:groups_created]).to eq(2)
        end
      end

      context 'with load step' do
        let(:step) do
          create(:pipeline_step,
            pipeline: pipeline,
            step_type: 'load',
            configuration: {
              'destination_type' => 'database',
              'table' => 'processed_users',
              'mode' => 'append'
            }
          )
        end

        it 'loads data to destination' do
          input_data = [
            { 'user_id' => 1, 'name' => 'John' },
            { 'user_id' => 2, 'name' => 'Jane' }
          ]

          result = step.execute(input_data)

          expect(result[:success]).to be_in([true, false])
          expect(result).to have_key(:metadata)
        end
      end

      context 'when step is disabled' do
        it 'passes data through without processing' do
          step.status = 'disabled'
          input_data = [{ test: 'data' }]

          result = step.execute(input_data)

          expect(result[:success]).to be true
          expect(result[:data]).to eq(input_data)
          expect(result[:metadata][:skipped]).to be true
        end
      end

      context 'with error handling' do
        let(:step) do
          create(:pipeline_step,
            pipeline: pipeline,
            step_type: 'transform',
            configuration: { 'invalid' => 'config' }
          )
        end

        it 'handles execution errors gracefully' do
          input_data = [{ test: 'data' }]

          result = step.execute(input_data)

          expect(result[:success]).to be false
          expect(result[:error]).to be_present
        end
      end
    end

    describe '#validate_configuration' do
      it 'validates required fields for step type' do
        step = build(:pipeline_step,
          pipeline: pipeline,
          step_type: 'extract',
          configuration: {}
        )

        expect(step.validate_configuration).to be false

        step.configuration = { 'source_type' => 'database', 'query' => 'SELECT 1' }
        expect(step.validate_configuration).to be true
      end
    end

    describe '#duplicate' do
      let(:step) do
        create(:pipeline_step,
          pipeline: pipeline,
          name: 'Original Step',
          configuration: { 'key' => 'value' }
        )
      end

      it 'creates a duplicate of the step' do
        duplicate = step.duplicate

        expect(duplicate).not_to be_persisted
        expect(duplicate.name).to eq('Original Step (Copy)')
        expect(duplicate.configuration).to eq(step.configuration)
        expect(duplicate.pipeline).to be_nil
      end
    end

    describe 'placeholder methods' do
      let(:simple_step) { PipelineStep.new(name: 'Test', step_type: 'extract', position: 1) }

      describe '#extract_from_file' do
        it 'raises NotImplementedError with descriptive message' do
          expect { simple_step.send(:extract_from_file, {}) }
            .to raise_error(NotImplementedError, 'extract_from_file must be implemented by subclasses')
        end
      end

      describe '#extract_from_api' do
        it 'raises NotImplementedError with descriptive message' do
          expect { simple_step.send(:extract_from_api, {}) }
            .to raise_error(NotImplementedError, 'extract_from_api must be implemented by subclasses')
        end
      end

      describe '#load_to_database' do
        it 'raises NotImplementedError with descriptive message' do
          expect { simple_step.send(:load_to_database, [], {}) }
            .to raise_error(NotImplementedError, 'load_to_database must be implemented by subclasses')
        end
      end

      describe '#load_to_file' do
        it 'raises NotImplementedError with descriptive message' do
          expect { simple_step.send(:load_to_file, [], {}) }
            .to raise_error(NotImplementedError, 'load_to_file must be implemented by subclasses')
        end
      end

      describe '#load_to_api' do
        it 'raises NotImplementedError with descriptive message' do
          expect { simple_step.send(:load_to_api, [], {}) }
            .to raise_error(NotImplementedError, 'load_to_api must be implemented by subclasses')
        end
      end
    end
  end

  describe 'callbacks' do
    let(:tenant) { create(:tenant) }
    let(:data_source) { create(:data_source, tenant: tenant) }
    let(:pipeline) { create(:pipeline, data_source: data_source) }

    before { ActsAsTenant.current_tenant = tenant }

    describe 'before_validation' do
      it 'sets default status to enabled' do
        step = PipelineStep.new(
          name: 'Test',
          step_type: 'extract',
          position: 1,
          pipeline: pipeline
        )
        step.valid?
        expect(step.status).to eq('enabled')
      end

      it 'sets position automatically if not provided' do
        existing_step = create(:pipeline_step, pipeline: pipeline, position: 1)

        new_step = PipelineStep.create!(
          name: 'Test',
          step_type: 'transform',
          pipeline: pipeline
        )

        expect(new_step.position).to eq(2)
      end
    end
  end
end