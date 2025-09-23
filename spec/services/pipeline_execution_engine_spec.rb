require 'rails_helper'

RSpec.describe PipelineExecutionEngine, type: :service do
  let(:tenant) { create(:tenant) }
  let(:data_source) { create(:data_source, tenant: tenant) }
  let(:pipeline) { create(:pipeline, data_source: data_source) }
  let(:execution_engine) { PipelineExecutionEngine.new(pipeline) }

  before { ActsAsTenant.current_tenant = tenant }

  describe '#initialize' do
    it 'initializes with a pipeline' do
      expect(execution_engine.pipeline).to eq(pipeline)
    end
  end

  describe '#execute' do
    context 'with a valid pipeline' do
      let!(:extract_step) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'extract',
          position: 1,
          configuration: {
            'source_type' => 'database',
            'query' => 'SELECT id, name, email FROM users LIMIT 5'
          }
        )
      end

      let!(:transform_step) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'transform',
          position: 2,
          configuration: {
            'transformations' => [
              { 'type' => 'uppercase', 'field' => 'name' }
            ]
          }
        )
      end

      let!(:load_step) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'load',
          position: 3,
          configuration: {
            'destination_type' => 'database',
            'table' => 'processed_users',
            'mode' => 'append'
          }
        )
      end

      it 'executes all pipeline steps in order' do
        result = execution_engine.execute

        expect(result[:success]).to be true
        expect(result[:pipeline_run]).to be_a(PipelineRun)
        expect(result[:pipeline_run].status).to eq('completed')
        expect(result[:pipeline_run].step_executions.count).to eq(3)
      end

      it 'creates step executions for each step' do
        execution_engine.execute

        step_executions = StepExecution.joins(:pipeline_step)
                                      .where(pipeline_steps: { pipeline: pipeline })
                                      .order('pipeline_steps.position')

        expect(step_executions.count).to eq(3)
        expect(step_executions.first.step_type).to eq('extract')
        expect(step_executions.second.step_type).to eq('transform')
        expect(step_executions.third.step_type).to eq('load')
      end

      it 'tracks execution timing' do
        result = execution_engine.execute

        pipeline_run = result[:pipeline_run]
        expect(pipeline_run.started_at).to be_present
        expect(pipeline_run.completed_at).to be_present
        expect(pipeline_run.duration).to be > 0
      end

      it 'tracks data flow between steps' do
        result = execution_engine.execute

        step_executions = result[:pipeline_run].step_executions.order(:created_at)

        extract_execution = step_executions.first
        expect(extract_execution.input_rows).to eq(0)
        expect(extract_execution.output_rows).to be > 0

        transform_execution = step_executions.second
        expect(transform_execution.input_rows).to eq(extract_execution.output_rows)
        expect(transform_execution.output_rows).to be > 0

        load_execution = step_executions.third
        expect(load_execution.input_rows).to eq(transform_execution.output_rows)
      end
    end

    context 'with disabled steps' do
      let!(:enabled_step) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'extract',
          position: 1,
          status: 'enabled'
        )
      end

      let!(:disabled_step) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'transform',
          position: 2,
          status: 'disabled'
        )
      end

      it 'skips disabled steps' do
        result = execution_engine.execute

        step_executions = result[:pipeline_run].step_executions

        expect(step_executions.count).to eq(1)
        expect(step_executions.first.pipeline_step).to eq(enabled_step)
      end
    end

    context 'with step execution errors' do
      let!(:failing_step) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'extract',
          position: 1,
          configuration: { 'invalid' => 'config' }
        )
      end

      let!(:following_step) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'transform',
          position: 2
        )
      end

      it 'stops execution on step failure' do
        result = execution_engine.execute

        expect(result[:success]).to be false
        expect(result[:pipeline_run].status).to eq('failed')
        expect(result[:pipeline_run].step_executions.count).to eq(1)
        expect(result[:pipeline_run].step_executions.first.status).to eq('failed')
      end

      it 'records error details' do
        result = execution_engine.execute

        failed_execution = result[:pipeline_run].step_executions.first
        expect(failed_execution.error_message).to be_present
      end
    end

    context 'with parallel execution mode' do
      let!(:step1) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'extract',
          position: 1,
          configuration: { 'execution_mode' => 'parallel' }
        )
      end

      let!(:step2) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'extract',
          position: 1,
          configuration: { 'execution_mode' => 'parallel' }
        )
      end

      let!(:step3) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'transform',
          position: 2
        )
      end

      it 'executes steps with same position in parallel' do
        start_time = Time.current
        result = execution_engine.execute
        execution_time = Time.current - start_time

        parallel_executions = result[:pipeline_run].step_executions
                                   .joins(:pipeline_step)
                                   .where(pipeline_steps: { position: 1 })

        expect(parallel_executions.count).to eq(2)
        expect(execution_time).to be < 2 # Should be faster than sequential
      end
    end

    context 'with dry run mode' do
      it 'simulates execution without actual data processing' do
        result = execution_engine.execute(dry_run: true)

        expect(result[:success]).to be true
        expect(result[:pipeline_run].status).to eq('completed')
        expect(result[:dry_run]).to be true
      end
    end

    context 'with invalid pipeline' do
      let(:empty_pipeline) { create(:pipeline, data_source: data_source) }
      let(:empty_execution_engine) { PipelineExecutionEngine.new(empty_pipeline) }

      it 'handles pipeline with no steps' do
        result = empty_execution_engine.execute

        expect(result[:success]).to be false
        expect(result[:error]).to include('no steps')
      end
    end

    context 'with pipeline not active' do
      before { pipeline.update!(status: 'draft') }

      it 'refuses to execute non-active pipeline' do
        result = execution_engine.execute

        expect(result[:success]).to be false
        expect(result[:error]).to include('not active')
      end
    end
  end

  describe '#stop' do
    let!(:long_running_step) do
      create(:pipeline_step,
        pipeline: pipeline,
        step_type: 'extract',
        position: 1,
        configuration: { 'simulate_delay' => 5 }
      )
    end

    it 'gracefully stops running execution' do
      # Start execution in background
      execution_thread = Thread.new { execution_engine.execute }

      # Give it time to start
      sleep(0.1)

      # Stop execution
      result = execution_engine.stop

      expect(result[:success]).to be true

      # Wait for thread to finish
      execution_thread.join(1)

      # Check if pipeline run was marked as stopped
      pipeline_run = PipelineRun.where(pipeline: pipeline).last
      expect(pipeline_run.status).to eq('stopped')
    end
  end

  describe '#resume' do
    let!(:extract_step) do
      create(:pipeline_step,
        pipeline: pipeline,
        step_type: 'extract',
        position: 1
      )
    end

    let!(:transform_step) do
      create(:pipeline_step,
        pipeline: pipeline,
        step_type: 'transform',
        position: 2
      )
    end

    it 'resumes execution from failed step' do
      # Create a failed pipeline run with one successful step
      pipeline_run = create(:pipeline_run,
        pipeline: pipeline,
        status: 'failed'
      )

      create(:step_execution,
        pipeline_run: pipeline_run,
        pipeline_step: extract_step,
        status: 'completed'
      )

      result = execution_engine.resume(pipeline_run)

      expect(result[:success]).to be true
      expect(result[:pipeline_run].step_executions.count).to eq(2)
    end
  end

  describe '#validate_pipeline' do
    context 'with valid pipeline' do
      let!(:step) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'extract'
        )
      end

      it 'returns validation success' do
        result = execution_engine.validate_pipeline

        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context 'with invalid configuration' do
      let!(:invalid_step) do
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'extract',
          configuration: {}
        )
      end

      it 'returns validation errors' do
        result = execution_engine.validate_pipeline

        expect(result[:valid]).to be false
        expect(result[:errors]).not_to be_empty
      end
    end
  end

  describe '#get_execution_status' do
    let!(:step) do
      create(:pipeline_step,
        pipeline: pipeline,
        step_type: 'extract'
      )
    end

    it 'returns current execution status' do
      execution_thread = Thread.new { execution_engine.execute }
      sleep(0.1)

      status = execution_engine.get_execution_status

      expect(status[:running]).to be true
      expect(status[:current_step]).to be_present

      execution_thread.join
    end
  end

  describe '#calculate_non_materializing_count' do
    # Create a minimal test instance without dependencies
    let(:test_pipeline) { double('Pipeline', id: 1) }
    let(:test_engine) { PipelineExecutionEngine.new(test_pipeline) }

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
        array = [ 1, 2, 3, 4, 5 ]
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
        allow(Array).to receive(:call).with(unknown).and_return([ 1, 2 ])

        expect(test_engine.send(:calculate_non_materializing_count, unknown)).to eq(2)
      end
    end
  end
end
