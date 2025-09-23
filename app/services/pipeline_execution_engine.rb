class PipelineExecutionEngine
  attr_reader :pipeline, :options

  def initialize(pipeline, options = {})
    @pipeline = pipeline
    @options = options
    @dry_run = options[:dry_run] || false
    @parallel = options[:parallel] || false
    @logger = Rails.logger
  end

  def execute
    return validation_error unless valid_for_execution?

    pipeline_run = create_pipeline_run

    if @dry_run
      return dry_run_execution(pipeline_run)
    end

    begin
      execute_pipeline_steps(pipeline_run)
      finalize_successful_run(pipeline_run)
    rescue StandardError => e
      handle_execution_error(pipeline_run, e)
    rescue Exception => e
      # Log critical errors that shouldn't normally be caught
      @logger.fatal "Critical error in pipeline execution: #{e.message}"
      handle_execution_error(pipeline_run, e)
      raise
    end
  end

  def can_execute?
    pipeline.active? && pipeline.can_run?
  end

  def estimate_duration
    return 0 if pipeline.pipeline_steps.empty?

    # Estimate based on input rows and historical performance
    total_estimated_seconds = pipeline.pipeline_steps.sum do |step|
      base_time = estimate_step_duration(step)
      complexity_multiplier = calculate_complexity_multiplier(step)
      base_time * complexity_multiplier
    end

    total_estimated_seconds
  end

  def validate_configuration
    validation_errors = []

    # Validate pipeline configuration
    validation_errors << "Pipeline must be active" unless pipeline.active?
    validation_errors << "Pipeline must have at least one step" if pipeline.pipeline_steps.empty?
    validation_errors << "Data source must be connected" unless pipeline.data_source.connected?

    # Validate each step configuration
    pipeline.pipeline_steps.each do |step|
      unless step.validate_configuration
        validation_errors << "Step '#{step.name}' has invalid configuration"
      end
    end

    {
      valid: validation_errors.empty?,
      errors: validation_errors
    }
  end

  def preview_execution
    {
      pipeline_id: pipeline.id,
      estimated_duration: estimate_duration,
      steps_count: pipeline.pipeline_steps.count,
      execution_plan: generate_execution_plan,
      resource_requirements: calculate_resource_requirements,
      validation: validate_configuration
    }
  end

  private

  def valid_for_execution?
    return false unless pipeline.present?
    return false unless pipeline.active?
    return false unless pipeline.data_source&.connected?
    return false if pipeline.pipeline_steps.empty?

    true
  end

  def validation_error
    {
      success: false,
      error: "Pipeline validation failed",
      details: validate_configuration[:errors]
    }
  end

  def create_pipeline_run
    pipeline.pipeline_runs.create!(
      status: "running",
      started_at: Time.current,
      trigger_type: options[:trigger_type] || "manual",
      metadata: {
        execution_options: options,
        environment: Rails.env,
        executor: "PipelineExecutionEngine"
      }
    )
  end

  def dry_run_execution(pipeline_run)
    @logger.info "Starting dry run for pipeline #{pipeline.id}"

    execution_plan = generate_execution_plan

    # Simulate step executions without actually running them
    pipeline.pipeline_steps.each do |step|
      create_step_execution(pipeline_run, step, simulate: true)
    end

    pipeline_run.update!(
      status: "completed",
      completed_at: Time.current,
      metadata: pipeline_run.metadata.merge({
        dry_run: true,
        execution_plan: execution_plan
      })
    )

    {
      success: true,
      pipeline_run: pipeline_run,
      dry_run: true,
      execution_plan: execution_plan
    }
  end

  def execute_pipeline_steps(pipeline_run)
    if @parallel && can_execute_in_parallel?
      execute_steps_in_parallel(pipeline_run)
    else
      execute_steps_sequentially(pipeline_run)
    end
  end

  def execute_steps_sequentially(pipeline_run)
    input_data = nil

    pipeline.pipeline_steps.order(:position).each do |step|
      @logger.info "Executing step: #{step.name} (#{step.step_type})"

      step_execution = create_step_execution(pipeline_run, step)

      begin
        result = execute_step(step, input_data, step_execution)

        if result[:success]
          step_execution.mark_completed!(
            calculate_non_materializing_count(result[:data]),
            result[:metadata] || {}
          )
          input_data = result[:data]
        else
          step_execution.mark_failed!(
            result[:error] || "Step execution failed",
            result[:metadata] || {}
          )
          raise PipelineExecutionError, "Step '#{step.name}' failed: #{result[:error]}"
        end

      rescue => e
        step_execution.mark_failed!(e.message, { error_type: e.class.name })
        raise
      end
    end

    input_data
  end

  def execute_steps_in_parallel(pipeline_run)
    # Group steps that can be executed in parallel
    step_groups = group_steps_for_parallel_execution

    step_groups.each do |group|
      if group.size == 1
        # Execute single step normally
        execute_step_group_sequentially(pipeline_run, group)
      else
        # Execute multiple steps in parallel
        execute_step_group_in_parallel(pipeline_run, group)
      end
    end
  end

  def execute_step_group_sequentially(pipeline_run, steps)
    steps.each do |step|
      step_execution = create_step_execution(pipeline_run, step)
      result = execute_step(step, nil, step_execution)

      if result[:success]
        step_execution.mark_completed!(
          calculate_non_materializing_count(result[:data]),
          result[:metadata] || {}
        )
      else
        step_execution.mark_failed!(
          result[:error] || "Step execution failed",
          result[:metadata] || {}
        )
        raise PipelineExecutionError, "Step '#{step.name}' failed: #{result[:error]}"
      end
    end
  end

  def execute_step_group_in_parallel(pipeline_run, steps)
    threads = []
    results = {}

    steps.each do |step|
      threads << Thread.new do
        step_execution = create_step_execution(pipeline_run, step)

        begin
          result = execute_step(step, nil, step_execution)

          if result[:success]
            step_execution.mark_completed!(
              calculate_non_materializing_count(result[:data]),
              result[:metadata] || {}
            )
            results[step.id] = { success: true, data: result[:data] }
          else
            step_execution.mark_failed!(
              result[:error] || "Step execution failed",
              result[:metadata] || {}
            )
            results[step.id] = { success: false, error: result[:error] }
          end

        rescue => e
          step_execution.mark_failed!(e.message, { error_type: e.class.name })
          results[step.id] = { success: false, error: e.message }
        end
      end
    end

    # Wait for all threads to complete
    threads.each { |t| t.join(30) } # 30 second timeout

    # Check if any threads are still alive
    stuck_threads = threads.select(&:alive?)
    if stuck_threads.any?
      stuck_threads.each(&:kill)
      raise PipelineExecutionError, "Parallel execution timeout - some steps did not complete"
    end

    # Check if any step failed
    failed_steps = results.select { |_, result| !result[:success] }
    if failed_steps.any?
      failed_step_names = failed_steps.map { |step_id, _|
        steps.find { |s| s.id == step_id }&.name
      }.compact
      raise PipelineExecutionError, "Parallel steps failed: #{failed_step_names.join(', ')}"
    end
  end

  def execute_step(step, input_data, step_execution)
    start_time = Time.current

    # Update input rows count - efficiently handle different data types without materializing
    input_count = calculate_non_materializing_count(input_data)
    step_execution.update!(input_rows: input_count)

    # Execute the step
    result = step.execute(input_data)

    # Log execution time
    execution_time = Time.current - start_time
    @logger.info "Step #{step.name} executed in #{execution_time.round(2)} seconds"

    result.merge(execution_time: execution_time)
  end

  def calculate_non_materializing_count(data)
    case data
    when nil
      0
    when ActiveRecord::Relation
      # ActiveRecord relations can count efficiently without loading records
      data.count
    when Array
      # Arrays are already materialized, use size or length
      data.size
    when Hash
      # Hashes are already materialized
      data.size
    else
      # For other objects, check available methods in order of preference
      if data.respond_to?(:count)
        # Many collections implement count efficiently
        data.count
      elsif data.respond_to?(:size)
        # Size is typically available for loaded collections
        data.size
      elsif data.respond_to?(:length)
        # Length is another common method for collections
        data.length
      elsif data.is_a?(Enumerable)
        # For generic Enumerables, we must iterate to count
        # This is a last resort as it may consume the enumerator
        count = 0
        data.each { count += 1 }
        count
      else
        # Fallback for truly unknown types - convert to array as last resort
        # This should rarely happen in practice
        @logger.warn "Unknown data type for counting: #{data.class}. Converting to array."
        Array(data).count
      end
    end
  end

  def create_step_execution(pipeline_run, step, simulate: false)
    step_execution = pipeline_run.step_executions.create!(
      pipeline_step: step,
      status: simulate ? "skipped" : "running",
      step_type: step.step_type,
      started_at: Time.current,
      input_rows: 0,
      output_rows: 0,
      metadata: simulate ? { simulated: true } : {}
    )

    if simulate
      step_execution.mark_skipped!("Dry run simulation")
    end

    step_execution
  end

  def finalize_successful_run(pipeline_run)
    pipeline_run.mark_completed!

    @logger.info "Pipeline #{pipeline.id} executed successfully"

    {
      success: true,
      pipeline_run: pipeline_run,
      total_rows_processed: pipeline_run.total_rows_processed,
      execution_time: pipeline_run.duration,
      steps_executed: pipeline_run.step_executions.completed.count
    }
  end

  def handle_execution_error(pipeline_run, error)
    @logger.error "Pipeline #{pipeline.id} execution failed: #{error.message}"
    @logger.error error.backtrace.join("\n") if Rails.env.development?

    pipeline_run.mark_failed!(error.message)

    {
      success: false,
      pipeline_run: pipeline_run,
      error: error.message,
      steps_completed: pipeline_run.step_executions.completed.count,
      steps_failed: pipeline_run.step_executions.failed.count
    }
  end

  def generate_execution_plan
    pipeline.pipeline_steps.order(:position).map do |step|
      {
        id: step.id,
        name: step.name,
        type: step.step_type,
        position: step.position,
        estimated_duration: estimate_step_duration(step),
        dependencies: calculate_step_dependencies(step),
        configuration_valid: step.validate_configuration
      }
    end
  end

  def calculate_resource_requirements
    {
      estimated_memory_mb: pipeline.pipeline_steps.sum { |step| estimate_memory_usage(step) },
      estimated_cpu_cores: calculate_cpu_requirements,
      estimated_disk_space_mb: estimate_disk_usage,
      network_bandwidth_required: estimate_network_usage
    }
  end

  def estimate_step_duration(step)
    # Base duration estimates by step type (in seconds)
    base_durations = {
      "extract" => 30,
      "transform" => 15,
      "filter" => 10,
      "validate" => 20,
      "aggregate" => 25,
      "load" => 35,
      "custom" => 20
    }

    base_durations[step.step_type] || 20
  end

  def calculate_complexity_multiplier(step)
    # Increase estimate based on configuration complexity
    multiplier = 1.0

    config = step.configuration || {}

    # Add complexity based on configuration size
    multiplier += (config.keys.count * 0.1)

    # Add complexity for specific step types
    case step.step_type
    when "transform"
      transformations = config["transformations"] || []
      multiplier += (transformations.count * 0.2)
    when "validate"
      validations = config["validations"] || []
      multiplier += (validations.count * 0.15)
    when "aggregate"
      aggregations = config["aggregations"] || []
      multiplier += (aggregations.count * 0.25)
    end

    multiplier
  end

  def calculate_step_dependencies(step)
    # For sequential execution, each step depends on the previous one
    previous_step_position = step.position - 1
    return [] if previous_step_position < 1

    previous_step = pipeline.pipeline_steps.find_by(position: previous_step_position)
    previous_step ? [ previous_step.id ] : []
  end

  def can_execute_in_parallel?
    # Simple heuristic: can execute in parallel if there are independent extract steps
    extract_steps = pipeline.pipeline_steps.where(step_type: "extract")
    extract_steps.count > 1
  end

  def group_steps_for_parallel_execution
    # Group steps that can be executed in parallel
    # For now, only extract steps can be executed in parallel
    groups = []
    current_group = []

    pipeline.pipeline_steps.order(:position).each do |step|
      if step.step_type == "extract" && current_group.empty?
        current_group << step
      elsif step.step_type == "extract" && current_group.last&.step_type == "extract"
        current_group << step
      else
        groups << current_group unless current_group.empty?
        current_group = [ step ]
      end
    end

    groups << current_group unless current_group.empty?
    groups
  end

  def estimate_memory_usage(step)
    # Estimate memory usage based on step type (in MB)
    base_memory = {
      "extract" => 100,
      "transform" => 150,
      "filter" => 75,
      "validate" => 100,
      "aggregate" => 200,
      "load" => 125,
      "custom" => 100
    }

    base_memory[step.step_type] || 100
  end

  def calculate_cpu_requirements
    # Estimate CPU cores needed
    step_count = pipeline.pipeline_steps.count
    parallel_capable_steps = pipeline.pipeline_steps.where(step_type: "extract").count

    [ @parallel ? [ parallel_capable_steps, 4 ].min : 1, step_count ].min
  end

  def estimate_disk_usage
    # Estimate temporary disk space needed (in MB)
    pipeline.pipeline_steps.sum do |step|
      case step.step_type
      when "extract", "load"
        500  # Larger for I/O operations
      else
        100  # Smaller for processing operations
      end
    end
  end

  def estimate_network_usage
    # Estimate network bandwidth (in Mbps)
    io_steps = pipeline.pipeline_steps.where(step_type: [ "extract", "load" ]).count
    io_steps * 10  # 10 Mbps per I/O step
  end
end

class PipelineExecutionError < StandardError; end
