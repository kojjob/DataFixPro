FactoryBot.define do
  factory :step_execution do
    association :pipeline_run
    association :pipeline_step

    status { 'running' }
    step_type { pipeline_step&.step_type || 'extract' }
    started_at { Time.current }
    input_rows { 0 }
    output_rows { 0 }

    trait :completed do
      status { 'completed' }
      completed_at { Time.current + 30.seconds }
      input_rows { 100 }
      output_rows { 95 }
    end

    trait :failed do
      status { 'failed' }
      completed_at { Time.current + 15.seconds }
      error_message { 'Step execution failed' }
      input_rows { 100 }
      output_rows { 0 }
    end

    trait :skipped do
      status { 'skipped' }
      completed_at { Time.current + 1.second }
      input_rows { 100 }
      output_rows { 100 }
    end

    after(:build) do |step_execution|
      if step_execution.completed_at.present? && step_execution.started_at.present?
        step_execution.duration = (step_execution.completed_at - step_execution.started_at).to_i
      end
    end
  end
end