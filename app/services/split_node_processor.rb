require 'digest'

class SplitNodeProcessor
  def process(node, context)
    # Get input data
    input_data = context['input-1'] || context[node['id']]

    # Validate input
    if input_data.nil?
      return { success: false, error: 'Missing input data' }
    end

    if input_data.empty?
      return { success: false, error: 'Empty input data' }
    end

    # Get split configuration
    split_type = node['data']['splitType'] if node['data']

    if split_type.nil?
      return { success: false, error: 'Split type not specified' }
    end

    begin
      # Perform split based on type
      result = case split_type
      when 'conditional'
        conditional_split(input_data, node['data'])
      when 'random'
        random_split(input_data, node['data'])
      when 'hash'
        hash_split(input_data, node['data'])
      when 'round-robin'
        round_robin_split(input_data, node['data'])
      else
        { success: false, error: "Unsupported split type: #{split_type}" }
      end

      result
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end

  private

  def conditional_split(input_data, config)
    conditions = config['conditions'] || []

    if conditions.empty?
      return { success: false, error: 'No conditions specified for conditional split' }
    end

    headers = input_data[0]
    rows = input_data[1..] || []

    # Initialize outputs for each condition
    outputs = {}
    statistics = {}

    conditions.each_with_index do |_condition, index|
      output_name = "output#{index + 1}"
      outputs[output_name] = [headers.dup]
      statistics[output_name] = 0
    end

    # Process each row
    rows.each do |row|
      matched = false

      conditions.each_with_index do |condition, index|
        if condition['isElse']
          # Else condition - matches if nothing else matched
          if !matched
            output_name = "output#{index + 1}"
            outputs[output_name] << row
            statistics[output_name] += 1
            matched = true
          end
        elsif evaluate_condition(row, headers, condition)
          # Regular condition matched
          output_name = "output#{index + 1}"
          outputs[output_name] << row
          statistics[output_name] += 1
          matched = true
          break # First match wins
        end
      end

      # If no condition matched and there's no else clause,
      # the row is dropped (or we could add it to a default output)
    end

    {
      success: true,
      outputs: outputs,
      statistics: statistics
    }
  end

  def evaluate_condition(row, headers, condition)
    field_index = headers.index(condition['field'])

    if field_index.nil?
      raise "Field not found: #{condition['field']}"
    end

    field_value = row[field_index]
    compare_value = condition['value']
    operator = condition['operator']

    # Try to convert to numbers if they look numeric
    field_val = try_numeric(field_value)
    compare_val = try_numeric(compare_value)

    case operator
    when '='
      field_val == compare_val
    when '!='
      field_val != compare_val
    when '>'
      field_val > compare_val
    when '>='
      field_val >= compare_val
    when '<'
      field_val < compare_val
    when '<='
      field_val <= compare_val
    else
      false
    end
  end

  def random_split(input_data, config)
    split_ratio = config['splitRatio'] || [50, 50]

    # Validate ratio
    if split_ratio.sum != 100
      return { success: false, error: 'Split ratio must sum to 100' }
    end

    headers = input_data[0]
    rows = input_data[1..] || []

    # Initialize outputs
    outputs = {}
    statistics = {}

    split_ratio.each_with_index do |_ratio, index|
      output_name = "output#{index + 1}"
      outputs[output_name] = [headers.dup]
      statistics[output_name] = 0
    end

    # Randomly distribute rows according to ratio
    rows.each do |row|
      random_value = rand(100)
      cumulative = 0

      split_ratio.each_with_index do |ratio, index|
        cumulative += ratio
        if random_value < cumulative
          output_name = "output#{index + 1}"
          outputs[output_name] << row
          statistics[output_name] += 1
          break
        end
      end
    end

    {
      success: true,
      outputs: outputs,
      statistics: statistics
    }
  end

  def hash_split(input_data, config)
    hash_field = config['hashField']
    buckets = config['buckets'] || 2

    headers = input_data[0]
    rows = input_data[1..] || []

    # Find hash field index
    field_index = headers.index(hash_field)
    if field_index.nil?
      return { success: false, error: "Hash field not found: #{hash_field}" }
    end

    # Initialize outputs
    outputs = {}
    statistics = {}

    buckets.times do |i|
      output_name = "output#{i + 1}"
      outputs[output_name] = [headers.dup]
      statistics[output_name] = 0
    end

    # Distribute rows based on hash
    rows.each do |row|
      field_value = row[field_index]
      # Use MD5 hash for distribution
      hash_value = Digest::MD5.hexdigest(field_value.to_s)
      # Convert first 8 hex chars to integer and modulo by bucket count
      bucket_index = hash_value[0..7].to_i(16) % buckets

      output_name = "output#{bucket_index + 1}"
      outputs[output_name] << row
      statistics[output_name] += 1
    end

    {
      success: true,
      outputs: outputs,
      statistics: statistics
    }
  end

  def round_robin_split(input_data, config)
    num_outputs = config['outputs'] || 2

    headers = input_data[0]
    rows = input_data[1..] || []

    # Initialize outputs
    outputs = {}
    statistics = {}

    num_outputs.times do |i|
      output_name = "output#{i + 1}"
      outputs[output_name] = [headers.dup]
      statistics[output_name] = 0
    end

    # Distribute rows in round-robin fashion
    rows.each_with_index do |row, index|
      output_index = index % num_outputs
      output_name = "output#{output_index + 1}"
      outputs[output_name] << row
      statistics[output_name] += 1
    end

    {
      success: true,
      outputs: outputs,
      statistics: statistics
    }
  end

  def try_numeric(value)
    return value if value.nil?

    if value =~ /^\d+$/
      value.to_i
    elsif value =~ /^\d+\.\d+$/
      value.to_f
    else
      value
    end
  end
end