class ValidationNodeProcessor
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

    # Get validation configuration
    validation_mode = node['data']['validationMode'] || 'strict'
    validation_rules = node['data']['validationRules'] || []

    if validation_rules.empty?
      return { success: false, error: 'No validation rules specified' }
    end

    begin
      # Perform validation
      perform_validation(input_data, validation_rules, validation_mode)
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end

  private

  def perform_validation(input_data, validation_rules, validation_mode)
    headers = input_data[0]
    rows = input_data[1..] || []

    # Validate that all rule fields exist
    validation_rules.each do |rule|
      unless headers.include?(rule['field'])
        raise "Field not found: #{rule['field']}"
      end
    end

    # Initialize outputs
    valid_output = [headers.dup]
    invalid_output = [headers.dup]

    # Statistics tracking
    total_records = 0
    valid_records = 0
    invalid_records = 0
    error_counts = Hash.new(0)

    # Process each row
    rows.each do |row|
      total_records += 1
      validation_errors = []

      # Check all validation rules for this row
      validation_rules.each do |rule|
        field_index = headers.index(rule['field'])
        field_value = row[field_index]

        unless validate_field(field_value, rule)
          validation_errors << rule['field']
          error_counts[rule['field']] += 1
        end
      end

      # Route to appropriate output
      if validation_errors.empty?
        valid_output << row
        valid_records += 1
      else
        invalid_output << row
        invalid_records += 1

        # In strict mode, stop on first error
        if validation_mode == 'strict'
          break
        end
      end
    end

    {
      success: true,
      outputs: {
        'valid' => valid_output,
        'invalid' => invalid_output
      },
      statistics: {
        totalRecords: total_records,
        validRecords: valid_records,
        invalidRecords: invalid_records,
        errors: error_counts
      }
    }
  end

  def validate_field(value, rule)
    case rule['type']
    when 'required'
      validate_required(value)
    when 'format'
      validate_format(value, rule['rule'])
    when 'range'
      validate_range(value, rule['min'], rule['max'])
    when 'enum'
      validate_enum(value, rule['values'])
    when 'pattern'
      validate_pattern(value, rule['pattern'])
    when 'custom'
      validate_custom(value, rule['expression'])
    else
      raise "Unsupported validation type: #{rule['type']}"
    end
  end

  def validate_required(value)
    !value.nil? && !value.to_s.strip.empty?
  end

  def validate_format(value, format_type)
    return false if value.nil? || value.empty?

    case format_type
    when 'email'
      # Simple email regex
      value =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    when 'phone'
      # Simple phone regex (XXX-XXX-XXXX or similar)
      value =~ /\A\d{3}-\d{3}-\d{4}\z/
    when 'date'
      # Simple date format (YYYY-MM-DD)
      value =~ /\A\d{4}-\d{2}-\d{2}\z/
    when 'url'
      # Simple URL regex
      value =~ /\Ahttps?:\/\/[\w\-]+(\.[\w\-]+)+[\/#?]?.*\z/i
    else
      true # Unknown format passes by default
    end
  end

  def validate_range(value, min, max)
    return false if value.nil? || value.to_s.empty?

    numeric_value = value.to_f
    numeric_value >= min && numeric_value <= max
  end

  def validate_enum(value, allowed_values)
    return false if value.nil?
    return false unless allowed_values.is_a?(Array)

    allowed_values.include?(value)
  end

  def validate_pattern(value, pattern)
    return false if value.nil? || value.empty?
    return false if pattern.nil? || pattern.empty?

    regex = Regexp.new(pattern)
    !!(value =~ regex)
  end

  def validate_custom(value, expression)
    return false if value.nil?
    return false if expression.nil? || expression.empty?

    # For security, we should not use eval in production
    # This is a simplified implementation for demonstration
    # In production, use a safe expression evaluator or predefined functions

    # Simple custom validation examples
    if expression.include?('length')
      # Handle length-based validations
      if expression =~ /value\.length\s*>=\s*(\d+)/
        min_length = $1.to_i
        return false if value.to_s.length < min_length
      end
    end

    if expression.include?('test')
      # Handle regex test validations
      if expression.include?('/[A-Z]/.test(value)')
        return false unless value =~ /[A-Z]/
      end
      if expression.include?('/[0-9]/.test(value)')
        return false unless value =~ /[0-9]/
      end
    end

    # For complex custom validations, return true by default
    # In production, implement a proper expression evaluator
    true
  end
end