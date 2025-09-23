class PipelineStep < ApplicationRecord
  belongs_to :pipeline
  has_many :step_executions, dependent: :destroy

  validates :name, presence: true
  validates :step_type, presence: true, inclusion: { in: %w[extract transform load filter validate aggregate custom] }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :status, inclusion: { in: %w[enabled disabled] }

  scope :enabled, -> { where(status: 'enabled') }
  scope :disabled, -> { where(status: 'disabled') }

  before_validation :set_defaults, if: :new_record?
  before_validation :set_position, if: -> { position.blank? }

  def enabled?
    status == 'enabled'
  end

  def execute(input_data)
    return skip_execution(input_data) unless enabled?

    begin
      result = case step_type
               when 'extract'
                 execute_extract
               when 'transform'
                 execute_transform(input_data)
               when 'filter'
                 execute_filter(input_data)
               when 'validate'
                 execute_validate(input_data)
               when 'aggregate'
                 execute_aggregate(input_data)
               when 'load'
                 execute_load(input_data)
               when 'custom'
                 execute_custom(input_data)
               else
                 raise "Unknown step type: #{step_type}"
               end

      {
        success: true,
        data: result[:data],
        metadata: result[:metadata] || {}
      }
    rescue StandardError => e
      Rails.logger.error "Step execution failed for #{name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        success: false,
        error: e.message,
        data: input_data,
        metadata: { error_type: e.class.name, step_id: id }
      }
    end
  end

  def validate_configuration
    case step_type
    when 'extract'
      validate_extract_config
    when 'transform'
      validate_transform_config
    when 'filter'
      validate_filter_config
    when 'validate'
      validate_validate_config
    when 'aggregate'
      validate_aggregate_config
    when 'load'
      validate_load_config
    else
      true
    end
  end

  def duplicate
    duplicate_step = dup
    duplicate_step.name = "#{name} (Copy)"
    duplicate_step.pipeline = nil
    duplicate_step
  end

  private

  def set_defaults
    self.status ||= 'enabled'
  end

  def set_position
    return unless pipeline

    pipeline.with_lock do
      max_position = pipeline.pipeline_steps.maximum(:position) || 0
      self.position = max_position + 1
    end
  end

  def skip_execution(input_data)
    {
      success: true,
      data: input_data,
      metadata: { skipped: true, reason: 'Step disabled' }
    }
  end

  def execute_extract
    config = configuration.with_indifferent_access

    case config['source_type']
    when 'database'
      extract_from_database(config)
    when 'file'
      extract_from_file(config)
    when 'api'
      extract_from_api(config)
    else
      raise "Unknown source type: #{config['source_type']}"
    end
  end

  def execute_transform(input_data)
    config = configuration.with_indifferent_access
    transformations = config['transformations'] || []

    transformed_data = Array(input_data).map do |row|
      apply_transformations(row, transformations)
    end

    {
      data: transformed_data,
      metadata: { rows_transformed: transformed_data.count }
    }
  end

  def execute_filter(input_data)
    config = configuration.with_indifferent_access
    condition = config['condition']

    filtered_data = Array(input_data).select do |row|
      evaluate_condition(row, condition)
    end

    original_count = case input_data
                    when ActiveRecord::Relation
                      input_data.count
                    when Array
                      input_data.size
                    when nil
                      0
                    else
                      input_data.respond_to?(:count) ? input_data.count : Array(input_data).count
                    end
    filtered_count = original_count - filtered_data.count

    {
      data: filtered_data,
      metadata: {
        rows_filtered: filtered_count,
        rows_remaining: filtered_data.count
      }
    }
  end

  def execute_validate(input_data)
    config = configuration.with_indifferent_access
    validations = config['validations'] || []

    validation_errors = []
    validated_data = Array(input_data).each_with_index.map do |row, index|
      row_errors = validate_row(row, validations)
      validation_errors.concat(row_errors.map { |error| error.merge(row_index: index) }) if row_errors.any?
      row
    end

    {
      data: validated_data,
      metadata: {
        validation_errors: validation_errors,
        error_count: validation_errors.count
      }
    }
  end

  def execute_aggregate(input_data)
    config = configuration.with_indifferent_access
    group_by = config['group_by']
    aggregations = config['aggregations'] || []

    grouped_data = Array(input_data).group_by { |row| row[group_by] }

    aggregated_data = grouped_data.map do |group_value, rows|
      result = { group_by => group_value }

      aggregations.each do |agg|
        field = agg['field']
        function = agg['function']
        alias_name = agg['alias'] || "#{function}_#{field}"

        result[alias_name] = calculate_aggregation(rows, field, function)
      end

      result
    end

    {
      data: aggregated_data,
      metadata: { groups_created: aggregated_data.count }
    }
  end

  def execute_load(input_data)
    config = configuration.with_indifferent_access

    case config['destination_type']
    when 'database'
      load_to_database(input_data, config)
    when 'file'
      load_to_file(input_data, config)
    when 'api'
      load_to_api(input_data, config)
    else
      raise "Unknown destination type: #{config['destination_type']}"
    end
  end

  def execute_custom(input_data)
    # Custom step implementation would go here
    # For now, just pass through
    { data: input_data, metadata: { custom_step: true } }
  end

  # Helper methods for different step types
  def extract_from_database(config)
    connector = pipeline.data_source.connector
    result = connector.execute_query(config['query'])

    if result[:success]
      {
        data: result[:data],
        metadata: { rows_extracted: result[:row_count] || result[:data].count }
      }
    else
      raise "Database extraction failed: #{result[:error]}"
    end
  end

  def extract_from_file(config)
    raise NotImplementedError, "extract_from_file must be implemented by subclasses"
  end

  def extract_from_api(config)
    raise NotImplementedError, "extract_from_api must be implemented by subclasses"
  end

  def apply_transformations(row, transformations)
    result = row.dup

    transformations.each do |transform|
      case transform['type']
      when 'rename'
        if result.key?(transform['from'])
          result[transform['to']] = result.delete(transform['from'])
        end
      when 'uppercase'
        field = transform['field']
        result[field] = result[field].to_s.upcase if result.key?(field)
      when 'lowercase'
        field = transform['field']
        result[field] = result[field].to_s.downcase if result.key?(field)
      when 'add_field'
        result[transform['field']] = transform['value']
      when 'remove_field'
        result.delete(transform['field'])
      end
    end

    result
  end

  def evaluate_condition(row, condition)
    field = condition['field']
    operator = condition['operator']
    value = condition['value']

    row_value = row[field]

    case operator
    when '='
      row_value == value
    when '!='
      row_value != value
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
    when 'starts_with'
      row_value.to_s.start_with?(value.to_s)
    when 'ends_with'
      row_value.to_s.end_with?(value.to_s)
    else
      false
    end
  end

  def validate_row(row, validations)
    errors = []

    validations.each do |validation|
      field = validation['field']
      type = validation['type']

      case type
      when 'required'
        if row[field].blank?
          errors << { field: field, type: 'required', message: "#{field} is required" }
        end
      when 'format'
        pattern = validation['pattern']
        if pattern == 'email' && row[field].present?
          unless row[field].match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
            errors << { field: field, type: 'format', message: "#{field} is not a valid email" }
          end
        end
      when 'range'
        min_val = validation['min']
        max_val = validation['max']
        value = row[field].to_f

        if min_val && value < min_val
          errors << { field: field, type: 'range', message: "#{field} must be >= #{min_val}" }
        end

        if max_val && value > max_val
          errors << { field: field, type: 'range', message: "#{field} must be <= #{max_val}" }
        end
      end
    end

    errors
  end

  def calculate_aggregation(rows, field, function)
    values = rows.map { |row| row[field] }

    case function
    when 'sum'
      values.map(&:to_f).sum
    when 'avg', 'average'
      values.map(&:to_f).sum / values.count.to_f
    when 'count'
      values.count
    when 'min'
      values.map(&:to_f).min
    when 'max'
      values.map(&:to_f).max
    else
      0
    end
  end

  def load_to_database(input_data, config)
    raise NotImplementedError, "load_to_database must be implemented by subclasses"
  end

  def load_to_file(input_data, config)
    raise NotImplementedError, "load_to_file must be implemented by subclasses"
  end

  def load_to_api(input_data, config)
    raise NotImplementedError, "load_to_api must be implemented by subclasses"
  end

  # Validation methods for different step configurations
  def validate_extract_config
    config = configuration.with_indifferent_access
    config['source_type'].present? &&
    (config['query'].present? || config['file_path'].present? || config['api_url'].present?)
  end

  def validate_transform_config
    config = configuration.with_indifferent_access
    config['transformations'].present? && config['transformations'].is_a?(Array)
  end

  def validate_filter_config
    config = configuration.with_indifferent_access
    config['condition'].present? && config['condition']['field'].present?
  end

  def validate_validate_config
    config = configuration.with_indifferent_access
    config['validations'].present? && config['validations'].is_a?(Array)
  end

  def validate_aggregate_config
    config = configuration.with_indifferent_access
    config['group_by'].present? && config['aggregations'].present?
  end

  def validate_load_config
    config = configuration.with_indifferent_access
    config['destination_type'].present?
  end
end