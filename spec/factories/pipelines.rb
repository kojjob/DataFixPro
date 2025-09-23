FactoryBot.define do
  factory :pipeline do
    association :tenant
    association :data_source

    sequence(:name) { |n| "Pipeline #{n}" }
    description { "A test pipeline for data processing" }
    status { 'draft' }
    schedule_type { 'manual' }

    trait :active do
      status { 'active' }
    end

    trait :scheduled do
      schedule_type { 'scheduled' }
      schedule_cron { '0 0 * * *' } # Daily at midnight
    end

    trait :with_interval do
      schedule_type { 'scheduled' }
      schedule_interval { 3600 } # 1 hour
    end

    trait :with_steps do
      after(:create) do |pipeline|
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'extract',
          position: 1
        )
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'transform',
          position: 2
        )
        create(:pipeline_step,
          pipeline: pipeline,
          step_type: 'load',
          position: 3
        )
      end
    end
  end
end
