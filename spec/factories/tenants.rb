FactoryBot.define do
  factory :tenant do
    sequence(:name) { |n| "Tenant #{n}" }
    sequence(:subdomain) { |n| "tenant#{n}" }
    sequence(:api_key) { |n| "api_key_#{n}" }
    plan { "starter" }
    status { "active" }
    settings { {} }
    plan_changes { [] }
  end
end