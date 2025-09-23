FactoryBot.define do
  factory :pipeline_step do
    association :pipeline

    sequence(:name) { |n| "Step #{n}" }
    step_type { 'extract' }
    position { 1 }
    status { 'enabled' }
    description { "A test pipeline step" }
    configuration do
      case step_type
      when 'extract'
        {
          'source_type' => 'database',
          'query' => 'SELECT * FROM users LIMIT 10'
        }
      when 'transform'
        {
          'transformations' => [
            { 'type' => 'rename', 'from' => 'id', 'to' => 'user_id' }
          ]
        }
      when 'filter'
        {
          'condition' => { 'field' => 'status', 'operator' => '=', 'value' => 'active' }
        }
      when 'validate'
        {
          'validations' => [
            { 'field' => 'email', 'type' => 'format', 'pattern' => 'email' }
          ]
        }
      when 'aggregate'
        {
          'group_by' => 'department',
          'aggregations' => [
            { 'field' => 'salary', 'function' => 'sum', 'alias' => 'total_salary' }
          ]
        }
      when 'load'
        {
          'destination_type' => 'database',
          'table' => 'processed_data',
          'mode' => 'append'
        }
      else
        {}
      end
    end

    trait :extract do
      step_type { 'extract' }
    end

    trait :transform do
      step_type { 'transform' }
    end

    trait :filter do
      step_type { 'filter' }
    end

    trait :validate do
      step_type { 'validate' }
    end

    trait :aggregate do
      step_type { 'aggregate' }
    end

    trait :load do
      step_type { 'load' }
    end

    trait :disabled do
      status { 'disabled' }
    end
  end
end