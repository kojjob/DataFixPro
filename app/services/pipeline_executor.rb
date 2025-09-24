class PipelineExecutor
  attr_reader :pipeline, :execution_context, :execution_status

  def initialize(pipeline)
    @pipeline = pipeline
    @execution_context = {}
    @execution_status = {
      status: 'ready',
      progress: 0,
      current_node: nil,
      nodes_executed: 0
    }
    @metrics = {
      start_time: nil,
      end_time: nil,
      nodes_executed: 0,
      total_time: 0
    }
    @should_stop = false
  end

  def execute
    @metrics[:start_time] = Time.current
    @execution_status[:status] = 'running'

    # Validate pipeline
    validation_result = validate_pipeline
    unless validation_result[:valid]
      raise "Pipeline validation failed: #{validation_result[:errors].join(', ')}"
    end

    # Get execution order
    execution_order = get_execution_plan

    # Execute nodes in order
    execution_order.each_with_index do |node_id, index|
      break if @should_stop

      node = find_node(node_id)
      @execution_status[:current_node] = node_id
      @execution_status[:progress] = ((index + 1).to_f / execution_order.size * 100).round

      # Get input data for node
      input_data = get_node_input(node)

      # Execute node
      processor = get_processor_for_node(node)
      result = processor.process(node, input_data)

      unless result[:success]
        @execution_status[:status] = 'failed'
        raise "Node #{node_id} failed: #{result[:error]}"
      end

      # Store result in context
      # For output nodes, the whole result is the data
      if node[:type] == 'output'
        @execution_context[node_id] = result
      else
        @execution_context[node_id] = result[:data]
      end
      @metrics[:nodes_executed] += 1
    end

    @metrics[:end_time] = Time.current
    @metrics[:total_time] = (@metrics[:end_time] - @metrics[:start_time]).to_f
    @execution_status[:status] = @should_stop ? 'stopped' : 'completed'
    @execution_status[:progress] = 100 unless @should_stop

    # Return final output
    output_node = find_output_node
    {
      success: true,
      result: output_node ? @execution_context[output_node['id']] : @execution_context,
      metrics: @metrics
    }
  rescue => e
    @execution_status[:status] = 'failed'
    @execution_status[:error] = e.message
    {
      success: false,
      error: e.message,
      metrics: @metrics
    }
  end

  def validate_pipeline
    errors = []

    # Check for nodes and edges
    errors << 'Pipeline must have nodes' if @pipeline[:nodes].blank?

    # Validate node types
    if @pipeline[:nodes].present?
      valid_types = %w[input output transform validation join split]
      @pipeline[:nodes].each do |node|
        unless valid_types.include?(node[:type])
          errors << "invalid node type: #{node[:type]}"
        end
      end
    end

    # Check for cycles
    if has_cycles?
      errors << 'Pipeline contains cyclic dependencies'
    end

    # Validate edge references
    if @pipeline[:edges].present?
      node_ids = @pipeline[:nodes].map { |n| n[:id] }
      @pipeline[:edges].each do |edge|
        errors << "Edge references invalid node: #{edge[:source]}" unless node_ids.include?(edge[:source])
        errors << "Edge references invalid node: #{edge[:target]}" unless node_ids.include?(edge[:target])
      end
    end

    {
      valid: errors.empty?,
      errors: errors
    }
  end

  def get_execution_plan
    # Topological sort using Kahn's algorithm
    nodes = @pipeline[:nodes]
    edges = @pipeline[:edges] || []

    # Build adjacency list and in-degree count
    adj = {}
    in_degree = {}

    nodes.each do |node|
      adj[node[:id]] = []
      in_degree[node[:id]] = 0
    end

    edges.each do |edge|
      adj[edge[:source]] << edge[:target]
      in_degree[edge[:target]] += 1
    end

    # Find all nodes with no incoming edges
    queue = []
    in_degree.each do |node_id, degree|
      queue << node_id if degree == 0
    end

    result = []
    while !queue.empty?
      node = queue.shift
      result << node

      # Decrease in-degree for neighbors
      adj[node].each do |neighbor|
        in_degree[neighbor] -= 1
        queue << neighbor if in_degree[neighbor] == 0
      end
    end

    # Check if all nodes are included (no cycles)
    if result.size != nodes.size
      raise 'Pipeline contains cyclic dependencies'
    end

    result
  end

  def get_status
    {
      status: @execution_status[:status],
      progress: @execution_status[:progress],
      current_node: @execution_status[:current_node],
      nodes_executed: @metrics[:nodes_executed]
    }
  end

  def stop
    @should_stop = true
    @execution_status[:status] = 'stopping'
  end

  def get_history
    # In production, this would fetch from database
    []
  end

  private

  def find_node(node_id)
    @pipeline[:nodes].find { |n| n[:id] == node_id }
  end

  def find_output_node
    @pipeline[:nodes].find { |n| n[:type] == 'output' }
  end

  def get_node_input(node)
    # Get incoming edges for this node
    incoming_edges = (@pipeline[:edges] || []).select { |e| e[:target] == node[:id] }

    if incoming_edges.empty?
      # No input edges, return empty context
      {}
    elsif incoming_edges.size == 1
      # Single input, return that node's output
      source_id = incoming_edges.first[:source]
      { 'input-1' => @execution_context[source_id] }
    else
      # Multiple inputs, return all
      result = {}
      incoming_edges.each_with_index do |edge, index|
        result["input-#{index + 1}"] = @execution_context[edge[:source]]
      end
      result
    end
  end

  def get_processor_for_node(node)
    case node[:type]
    when 'input'
      InputNodeProcessor.new
    when 'output'
      OutputNodeProcessor.new
    when 'transform'
      TransformNodeProcessor.new
    when 'validation'
      ValidationNodeProcessor.new
    when 'join'
      JoinNodeProcessor.new
    when 'split'
      SplitNodeProcessor.new
    else
      raise "Unknown node type: #{node[:type]}"
    end
  end

  def has_cycles?
    return false if @pipeline[:edges].blank?

    # Build adjacency list
    adj = {}
    @pipeline[:nodes].each { |node| adj[node[:id]] = [] }
    @pipeline[:edges].each do |edge|
      adj[edge[:source]] ||= []
      adj[edge[:source]] << edge[:target]
    end

    # DFS to detect cycles
    visited = {}
    rec_stack = {}

    @pipeline[:nodes].each do |node|
      if !visited[node[:id]] && has_cycle_util?(node[:id], adj, visited, rec_stack)
        return true
      end
    end

    false
  end

  def has_cycle_util?(node, adj, visited, rec_stack)
    visited[node] = true
    rec_stack[node] = true

    adj[node]&.each do |neighbor|
      if !visited[neighbor]
        return true if has_cycle_util?(neighbor, adj, visited, rec_stack)
      elsif rec_stack[neighbor]
        return true
      end
    end

    rec_stack[node] = false
    false
  end
end