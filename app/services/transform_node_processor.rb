class TransformNodeProcessor
  def process(node, context)
    # Get input data
    input_data = context['input-1'] || context[node['id']]

    # Validate input
    if input_data.nil? || input_data.empty?
      return { success: false, error: 'Missing or empty input data' }
    end

    # Validate node configuration
    unless node['data']
      return { success: false, error: 'Node data missing' }
    end

    transform_type = node['data']['transformType']

    if transform_type.nil?
      return { success: false, error: 'Transform type not specified' }
    end

    begin
      # Process based on transform type
      result_data = case transform_type
      when 'column'
        process_column_transformations(input_data.dup, node['data'])
      when 'filter'
        process_row_filtering(input_data.dup, node['data'])
      when 'aggregate'
        process_aggregation(input_data.dup, node['data'])
      when 'sort'
        process_sorting(input_data.dup, node['data'])
      when 'expression'
        process_expressions(input_data.dup, node['data'])
      else
        return { success: false, error: "Unsupported transform type: #{transform_type}" }
      end

      { success: true, data: result_data }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end

  private

  def process_column_transformations(data, config)
    return data unless config['operations']

    headers = data[0]

    config['operations'].each do |operation|
      case operation['operation']
      when 'toNumber'
        apply_to_number(data, headers, operation)
      when 'lowercase'
        apply_lowercase(data, headers, operation)
      when 'uppercase'
        apply_uppercase(data, headers, operation)
      when 'multiply'
        apply_multiply(data, headers, operation)
      when 'concatenate'
        apply_concatenate(data, headers, operation)
      when 'drop'
        apply_drop_columns(data, headers, operation)
      when 'rename'
        apply_rename_column(data, headers, operation)
      else
        raise "Unknown operation: #{operation['operation']}"
      end
    end

    data
  end

  def apply_to_number(data, headers, operation)
    column = operation['column']
    column_index = headers.index(column)

    raise "Column not found: #{column}" unless column_index

    new_column = operation['newColumn']

    if new_column
      # Add new column
      data[0] << new_column

      # Convert values
      (1...data.size).each do |i|
        value = data[i][column_index]
        data[i] << value.to_f
      end
    else
      # Convert in place
      (1...data.size).each do |i|
        data[i][column_index] = data[i][column_index].to_f
      end
    end
  end

  def apply_lowercase(data, headers, operation)
    column = operation['column']
    column_index = headers.index(column)

    raise "Column not found: #{column}" unless column_index

    if operation['inPlace']
      # Convert in place
      (1...data.size).each do |i|
        data[i][column_index] = data[i][column_index].to_s.downcase
      end
    else
      new_column = operation['newColumn'] || "#{column}_lowercase"
      data[0] << new_column

      (1...data.size).each do |i|
        data[i] << data[i][column_index].to_s.downcase
      end
    end
  end

  def apply_uppercase(data, headers, operation)
    column = operation['column']
    column_index = headers.index(column)

    raise "Column not found: #{column}" unless column_index

    if operation['inPlace']
      # Convert in place
      (1...data.size).each do |i|
        data[i][column_index] = data[i][column_index].to_s.upcase
      end
    else
      new_column = operation['newColumn'] || "#{column}_uppercase"
      data[0] << new_column

      (1...data.size).each do |i|
        data[i] << data[i][column_index].to_s.upcase
      end
    end
  end

  def apply_multiply(data, headers, operation)
    column = operation['column']
    column_index = headers.index(column)

    raise "Column not found: #{column}" unless column_index

    value = operation['value']
    new_column = operation['newColumn'] || "#{column}_multiplied"

    # Add new column
    data[0] << new_column

    # Multiply values
    (1...data.size).each do |i|
      original_value = data[i][column_index].to_f
      data[i] << original_value * value
    end
  end

  def apply_concatenate(data, headers, operation)
    columns = operation['columns']
    separator = operation['separator'] || ''
    new_column = operation['newColumn']

    column_indices = columns.map { |col| headers.index(col) }

    if column_indices.any?(&:nil?)
      raise "One or more columns not found"
    end

    # Add new column
    data[0] << new_column

    # Concatenate values
    (1...data.size).each do |i|
      values = column_indices.map { |idx| data[i][idx] }
      data[i] << values.join(separator)
    end
  end

  def apply_drop_columns(data, headers, operation)
    columns = operation['columns']

    # Find indices to drop (in reverse order to avoid index shifting)
    indices_to_drop = columns.map { |col| headers.index(col) }.compact.sort.reverse

    # Remove columns from all rows
    data.each do |row|
      indices_to_drop.each { |idx| row.delete_at(idx) }
    end
  end

  def apply_rename_column(data, headers, operation)
    column = operation['column']
    new_name = operation['newName']
    column_index = headers.index(column)

    raise "Column not found: #{column}" unless column_index

    data[0][column_index] = new_name
  end

  def process_row_filtering(data, config)
    return data unless config['conditions']

    headers = data[0]
    conditions = config['conditions']
    logical_operator = config['logicalOperator'] || 'AND'

    # Keep header
    filtered_data = [headers]

    # Filter data rows
    (1...data.size).each do |i|
      row = data[i]

      if logical_operator == 'AND'
        # All conditions must be true
        if conditions.all? { |condition| evaluate_condition(row, headers, condition) }
          filtered_data << row
        end
      else # OR
        # At least one condition must be true
        if conditions.any? { |condition| evaluate_condition(row, headers, condition) }
          filtered_data << row
        end
      end
    end

    filtered_data
  end

  def evaluate_condition(row, headers, condition)
    column = condition['column']
    operator = condition['operator']
    value = condition['value']

    column_index = headers.index(column)
    return false unless column_index

    row_value = row[column_index]

    case operator
    when '='
      row_value.to_s == value.to_s
    when '!='
      row_value.to_s != value.to_s
    when '>'
      row_value.to_f > value.to_f
    when '<'
      row_value.to_f < value.to_f
    when '>='
      row_value.to_f >= value.to_f
    when '<='
      row_value.to_f <= value.to_f
    when 'contains'
      row_value.to_s.include?(value.to_s)
    when 'not_contains'
      !row_value.to_s.include?(value.to_s)
    else
      false
    end
  end

  def process_aggregation(data, config)
    return data if data.size <= 1

    headers = data[0]
    group_by = config['groupBy'] || []
    aggregations = config['aggregations'] || []

    # Find group column indices
    group_indices = group_by.map { |col| headers.index(col) }.compact

    # Group data
    groups = {}
    (1...data.size).each do |i|
      row = data[i]
      key = group_indices.map { |idx| row[idx] }
      groups[key] ||= []
      groups[key] << row
    end

    # Create result headers
    result_headers = group_by.dup
    aggregations.each do |agg|
      result_headers << (agg['alias'] || "#{agg['operation']}_#{agg['column']}")
    end

    # Perform aggregations
    result_data = [result_headers]

    groups.each do |key, rows|
      result_row = key.dup

      aggregations.each do |agg|
        column = agg['column']
        operation = agg['operation']
        column_index = headers.index(column)

        if column_index
          values = rows.map { |row| row[column_index] }

          aggregated_value = case operation
          when 'sum'
            values.map(&:to_f).sum
          when 'avg'
            values.map(&:to_f).sum / values.size.to_f
          when 'count'
            values.size
          when 'min'
            values.map(&:to_f).min
          when 'max'
            values.map(&:to_f).max
          else
            nil
          end

          result_row << aggregated_value
        else
          result_row << nil
        end
      end

      result_data << result_row
    end

    result_data
  end

  def process_sorting(data, config)
    return data if data.size <= 1

    headers = data[0]
    sort_by = config['sortBy'] || []

    return data if sort_by.empty?

    # Prepare sort criteria
    sort_criteria = sort_by.map do |sort|
      column_index = headers.index(sort['column'])
      direction = sort['direction'] || 'asc'
      [column_index, direction]
    end.compact

    # Separate headers and data
    data_rows = data[1..]

    # Sort data rows
    sorted_rows = data_rows.sort do |a, b|
      comparison = 0

      sort_criteria.each do |index, direction|
        next unless index

        val_a = a[index]
        val_b = b[index]

        # Try numeric comparison first
        if val_a.to_s =~ /^\d+(\.\d+)?$/ && val_b.to_s =~ /^\d+(\.\d+)?$/
          comparison = val_a.to_f <=> val_b.to_f
        else
          comparison = val_a.to_s <=> val_b.to_s
        end

        # Reverse for descending
        comparison = -comparison if direction == 'desc'

        break if comparison != 0
      end

      comparison
    end

    # Return headers + sorted data
    [headers] + sorted_rows
  end

  def process_expressions(data, config)
    return data unless config['expressions']

    headers = data[0]

    config['expressions'].each do |expr|
      expression = expr['expression']
      new_column = expr['newColumn']

      # Add new column header
      data[0] << new_column

      # Evaluate expression for each row
      (1...data.size).each do |i|
        row = data[i]

        # Create context for expression evaluation
        context = {}
        headers.each_with_index do |header, idx|
          context[header] = row[idx].to_f rescue row[idx]
        end

        # Simple expression evaluation (limited for security)
        result = evaluate_expression(expression, context)
        row << result
      end
    end

    data
  end

  def evaluate_expression(expression, context)
    # Very simple expression evaluator for basic math operations
    # In production, you'd want a proper expression parser

    # Replace column names with values
    evaluated = expression.dup
    context.each do |key, value|
      evaluated.gsub!(key, value.to_s)
    end

    # Evaluate basic math operations (unsafe in production!)
    # Only for demonstration - use a proper expression evaluator in production
    begin
      eval(evaluated)
    rescue
      nil
    end
  end
end