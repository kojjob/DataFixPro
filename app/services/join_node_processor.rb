class JoinNodeProcessor
  def process(node, context)
    # Extract node configuration
    join_type = node['data']['joinType'] || 'inner'
    join_conditions = node['data']['joinConditions'] || []
    selected_fields = node['data']['selectedFields'] || {}

    # Validate join conditions
    if join_conditions.empty?
      return { success: false, error: 'No join conditions specified' }
    end

    # Get left and right data from context
    # Try different naming conventions for inputs
    left_data = context['input-1'] || context["#{node['id']}:left"]
    right_data = context['input-2'] || context["#{node['id']}:right"]

    # Validate inputs
    if left_data.nil?
      return { success: false, error: 'Missing left input data' }
    end

    if right_data.nil?
      return { success: false, error: 'Missing right input data' }
    end

    if left_data.empty? || right_data.empty?
      return { success: false, error: 'Empty input data' }
    end

    begin
      # Perform the join operation
      result_data = perform_join(
        left_data,
        right_data,
        join_type,
        join_conditions,
        selected_fields
      )

      { success: true, data: result_data }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end

  private

  def perform_join(left_data, right_data, join_type, join_conditions, selected_fields)
    # Extract headers and data
    left_headers = left_data[0]
    left_rows = left_data[1..] || []
    right_headers = right_data[0]
    right_rows = right_data[1..] || []

    # Determine selected fields
    left_fields = selected_fields['left'] || left_headers
    right_fields = selected_fields['right'] || right_headers

    # Get field indices
    left_field_indices = get_field_indices(left_headers, left_fields)
    right_field_indices = get_field_indices(right_headers, right_fields)

    # Validate join condition fields exist
    join_conditions.each do |condition|
      unless left_headers.include?(condition['leftField'])
        raise "Field not found in left table: #{condition['leftField']}"
      end
      unless right_headers.include?(condition['rightField'])
        raise "Field not found in right table: #{condition['rightField']}"
      end
    end

    # Create result headers
    result_headers = left_fields + right_fields

    # Perform the join based on type
    result_rows = case join_type
    when 'inner'
      inner_join(left_rows, right_rows, left_headers, right_headers,
                 join_conditions, left_field_indices, right_field_indices)
    when 'left'
      left_join(left_rows, right_rows, left_headers, right_headers,
                join_conditions, left_field_indices, right_field_indices)
    when 'right'
      right_join(left_rows, right_rows, left_headers, right_headers,
                 join_conditions, left_field_indices, right_field_indices)
    when 'full'
      full_outer_join(left_rows, right_rows, left_headers, right_headers,
                      join_conditions, left_field_indices, right_field_indices)
    else
      raise "Unsupported join type: #{join_type}"
    end

    # Return result with headers
    [result_headers] + result_rows
  end

  def get_field_indices(headers, selected_fields)
    selected_fields.map { |field| headers.index(field) }.compact
  end

  def inner_join(left_rows, right_rows, left_headers, right_headers,
                 join_conditions, left_field_indices, right_field_indices)
    result = []

    left_rows.each do |left_row|
      right_rows.each do |right_row|
        if match_conditions?(left_row, right_row, left_headers, right_headers, join_conditions)
          result << build_joined_row(left_row, right_row, left_field_indices, right_field_indices)
        end
      end
    end

    result
  end

  def left_join(left_rows, right_rows, left_headers, right_headers,
                join_conditions, left_field_indices, right_field_indices)
    result = []

    left_rows.each do |left_row|
      matched = false
      right_rows.each do |right_row|
        if match_conditions?(left_row, right_row, left_headers, right_headers, join_conditions)
          result << build_joined_row(left_row, right_row, left_field_indices, right_field_indices)
          matched = true
        end
      end

      # If no match found, add left row with nulls for right columns
      unless matched
        null_right = Array.new(right_field_indices.length)
        result << build_joined_row(left_row, null_right, left_field_indices, (0...null_right.length).to_a)
      end
    end

    result
  end

  def right_join(left_rows, right_rows, left_headers, right_headers,
                 join_conditions, left_field_indices, right_field_indices)
    result = []

    right_rows.each do |right_row|
      matched = false
      left_rows.each do |left_row|
        if match_conditions?(left_row, right_row, left_headers, right_headers, join_conditions)
          result << build_joined_row(left_row, right_row, left_field_indices, right_field_indices)
          matched = true
        end
      end

      # If no match found, add right row with nulls for left columns
      unless matched
        null_left = Array.new(left_field_indices.length)
        result << build_joined_row(null_left, right_row, (0...null_left.length).to_a, right_field_indices)
      end
    end

    result
  end

  def full_outer_join(left_rows, right_rows, left_headers, right_headers,
                      join_conditions, left_field_indices, right_field_indices)
    result = []
    matched_right_indices = Set.new

    # First, do a left join
    left_rows.each do |left_row|
      matched = false
      right_rows.each_with_index do |right_row, right_index|
        if match_conditions?(left_row, right_row, left_headers, right_headers, join_conditions)
          result << build_joined_row(left_row, right_row, left_field_indices, right_field_indices)
          matched = true
          matched_right_indices.add(right_index)
        end
      end

      # If no match found, add left row with nulls for right columns
      unless matched
        null_right = Array.new(right_field_indices.length)
        result << build_joined_row(left_row, null_right, left_field_indices, (0...null_right.length).to_a)
      end
    end

    # Then add unmatched right rows
    right_rows.each_with_index do |right_row, right_index|
      unless matched_right_indices.include?(right_index)
        null_left = Array.new(left_field_indices.length)
        result << build_joined_row(null_left, right_row, (0...null_left.length).to_a, right_field_indices)
      end
    end

    result
  end

  def match_conditions?(left_row, right_row, left_headers, right_headers, join_conditions)
    join_conditions.all? do |condition|
      left_index = left_headers.index(condition['leftField'])
      right_index = right_headers.index(condition['rightField'])

      left_value = left_row[left_index]
      right_value = right_row[right_index]

      compare_values(left_value, right_value, condition['operator'])
    end
  end

  def compare_values(left_value, right_value, operator)
    # Convert to appropriate types for comparison
    left_val = try_numeric(left_value)
    right_val = try_numeric(right_value)

    case operator
    when '='
      left_val == right_val
    when '!='
      left_val != right_val
    when '<'
      left_val < right_val
    when '<='
      left_val <= right_val
    when '>'
      left_val > right_val
    when '>='
      left_val >= right_val
    else
      left_val == right_val # Default to equality
    end
  end

  def try_numeric(value)
    # Try to convert to number for comparison if it looks numeric
    return value if value.nil?

    if value =~ /^\d+$/
      value.to_i
    elsif value =~ /^\d+\.\d+$/
      value.to_f
    else
      value
    end
  end

  def build_joined_row(left_row, right_row, left_indices, right_indices)
    result = []

    # Add selected left fields
    left_indices.each do |index|
      result << (left_row.is_a?(Array) ? left_row[index] : nil)
    end

    # Add selected right fields
    right_indices.each do |index|
      result << (right_row.is_a?(Array) ? right_row[index] : nil)
    end

    result
  end
end