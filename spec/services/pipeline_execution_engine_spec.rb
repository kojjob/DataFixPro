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
end