FactoryBot.define do
  factory :pipeline_run do
    association :pipeline

    status { 'running' }
    started_at { Time.current }
    trigger_type { 'manual' }

    trait :completed do
      status { 'completed' }
      completed_at { Time.current + 1.minute }
    end

    trait :failed do
      status { 'failed' }
      completed_at { Time.current + 30.seconds }
      error_message { 'Test execution error' }
    end

    trait :stopped do
      status { 'stopped' }
      completed_at { Time.current + 15.seconds }
    end

    after(:build) do |pipeline_run|
      if pipeline_run.completed_at.present? && pipeline_run.started_at.present?
        pipeline_run.duration = (pipeline_run.completed_at - pipeline_run.started_at).to_i
      end
    end
  end
end