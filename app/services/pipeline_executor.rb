class PipelineExecutor
  attr_reader :pipeline

  def initialize(pipeline)
    @pipeline = pipeline
    @execution_context = {}
    @node_processors = {}
    @execution_metrics = {}
  end

  def execute
    return { success: false, error: 'No pipeline configuration' } unless @pipeline.configuration

    validation = validate_pipeline
    return validation unless validation[:valid]

    nodes = @pipeline.configuration['nodes'] || []
    edges = @pipeline.configuration['edges'] || []

    # Check for cycles
    if has_cycle?(nodes, edges)
      return { success: false, error: 'Cyclic dependency detected in pipeline' }
    end

    # Get execution order
    execution_order = get_execution_plan
    executed_nodes = []
    warnings = []
    statistics = {}
    start_time = Time.current

    # Find disconnected nodes
    connected_nodes = Set.new
    edges.each do |edge|
      connected_nodes.add(edge['source'])
      connected_nodes.add(edge['target'])
    end

    # Add source nodes (nodes with no incoming edges)
    nodes.each do |node|
      unless edges.any? { |e| e['target'] == node['id'] }
        connected_nodes.add(node['id'])
      end
    end

    nodes.each do |node|
      unless connected_nodes.include?(node['id'])
        warnings << "Node #{node['id']} is disconnected"
      end
    end

    # Execute nodes in order
    execution_order.each do |node_id|
      node = nodes.find { |n| n['id'] == node_id }
      next unless node

      node_start_time = Time.current

      begin
        processor = get_processor_for_node(node)
        result = processor.process(node, @execution_context)

        if result[:success]
          executed_nodes << node_id

          # Handle different result types
          if result[:outputs]
            # Split or Validation node with multiple outputs
            result[:outputs].each do |output_name, output_data|
              @execution_context["#{node_id}:#{output_name}"] = output_data
            end
          else
            # Regular node with single output
            @execution_context[node_id] = result[:data]
          end

          # Store statistics if present
          if result[:statistics]
            statistics[node_id.to_sym] = result[:statistics]
          end

          # Record execution time
          @execution_metrics[node_id] = Time.current - node_start_time
        else
          return {
            success: false,
            error: result[:error],
            failed_node: node_id,
            executed_nodes: executed_nodes
          }
        end
      rescue StandardError => e
        return {
          success: false,
          error: "Error executing node #{node_id}: #{e.message}",
          failed_node: node_id,
          executed_nodes: executed_nodes
        }
      end
    end

    {
      success: true,
      executed_nodes: executed_nodes,
      warnings: warnings,
      statistics: statistics,
      metrics: {
        total_execution_time: Time.current - start_time,
        node_execution_times: @execution_metrics
      }
    }
  end

  def validate_pipeline
    errors = []
    warnings = []

    nodes = @pipeline.configuration['nodes'] || []
    edges = @pipeline.configuration['edges'] || []

    # Check for valid node types
    valid_types = %w[input output transform join split validation filter aggregate]
    nodes.each do |node|
      unless valid_types.include?(node['type'])
        errors << "Unknown node type: #{node['type']}"
      end
    end

    # Check edge references
    node_ids = nodes.map { |n| n['id'] }
    edges.each do |edge|
      unless node_ids.include?(edge['source'])
        errors << "Edge references non-existent node: #{edge['source']}"
      end
      unless node_ids.include?(edge['target'])
        errors << "Edge references non-existent node: #{edge['target']}"
      end
    end

    # Check for output nodes
    output_nodes = nodes.select { |n| n['type'] == 'output' }
    if output_nodes.empty?
      warnings << 'No output nodes detected'
    end

    # Check for input nodes
    input_nodes = nodes.select { |n| n['type'] == 'input' }
    if input_nodes.empty? && nodes.any?
      warnings << 'No input nodes detected'
    end

    {
      valid: errors.empty?,
      errors: errors,
      warnings: warnings
    }
  end

  def get_execution_plan
    nodes = @pipeline.configuration['nodes'] || []
    edges = @pipeline.configuration['edges'] || []

    # Build adjacency list
    graph = Hash.new { |h, k| h[k] = [] }
    in_degree = Hash.new(0)

    # Initialize all nodes
    nodes.each { |node| in_degree[node['id']] = 0 }

    # Build graph and calculate in-degrees
    edges.each do |edge|
      graph[edge['source']] << edge['target']
      in_degree[edge['target']] += 1
    end

    # Topological sort using Kahn's algorithm
    queue = []
    in_degree.each do |node, degree|
      queue << node if degree == 0
    end

    sorted_order = []
    while !queue.empty?
      node = queue.shift
      sorted_order << node

      graph[node].each do |neighbor|
        in_degree[neighbor] -= 1
        queue << neighbor if in_degree[neighbor] == 0
      end
    end

    sorted_order
  end

  private

  def has_cycle?(nodes, edges)
    # Build adjacency list
    graph = Hash.new { |h, k| h[k] = [] }
    edges.each do |edge|
      graph[edge['source']] << edge['target']
    end

    # Track visited nodes and nodes in current path
    visited = Set.new
    rec_stack = Set.new

    # Check each node for cycles
    nodes.each do |node|
      if dfs_has_cycle?(node['id'], graph, visited, rec_stack)
        return true
      end
    end

    false
  end

  def dfs_has_cycle?(node, graph, visited, rec_stack)
    visited.add(node)
    rec_stack.add(node)

    graph[node].each do |neighbor|
      if !visited.include?(neighbor)
        return true if dfs_has_cycle?(neighbor, graph, visited, rec_stack)
      elsif rec_stack.include?(neighbor)
        return true
      end
    end

    rec_stack.delete(node)
    false
  end

  def get_processor_for_node(node)
    processor_class = case node['type']
    when 'input'
      InputNodeProcessor
    when 'output'
      OutputNodeProcessor
    when 'transform'
      TransformNodeProcessor
    when 'join'
      JoinNodeProcessor
    when 'split'
      SplitNodeProcessor
    when 'validation'
      ValidationNodeProcessor
    when 'filter'
      FilterNodeProcessor
    when 'aggregate'
      AggregateNodeProcessor
    else
      raise "Unknown node type: #{node['type']}"
    end

    processor_class.new
  end
end