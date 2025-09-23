FactoryBot.define do
  factory :tenant do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:subdomain) { |n| "company-#{n}" }
    sequence(:api_key) { |n| "api_key_#{n}" }
    plan { "starter" }
    status { "active" }
    plan_changes { [] }

    settings do
      {
        timezone: "UTC",
        date_format: "YYYY-MM-DD",
        currency: "USD",
        language: "en"
      }
    end

    trait :professional do
      plan { "professional" }
    end

    trait :enterprise do
      plan { "enterprise" }
    end

    trait :inactive do
      status { "inactive" }
    end

    trait :suspended do
      status { "suspended" }
      suspended_at { Time.current }
    end

    trait :with_custom_domain do
      sequence(:custom_domain) { |n| "analytics#{n}.company.com" }
    end

    trait :with_users do
      transient do
        users_count { 3 }
      end

      after(:create) do |tenant, evaluator|
        create_list(:user, evaluator.users_count, tenant: tenant)
      end
    end

    trait :with_data_sources do
      transient do
        data_sources_count { 2 }
      end

      after(:create) do |tenant, evaluator|
        create_list(:data_source, evaluator.data_sources_count, tenant: tenant)
      end
    end
  end
end
