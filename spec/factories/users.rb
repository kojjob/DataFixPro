FactoryBot.define do
  factory :user do
    association :tenant
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    sequence(:name) { |n| "User #{n}" }
    status { 'active' }

    trait :admin do
      after(:create) do |user|
        admin_role = user.tenant.roles.find_or_create_by!(name: 'admin')
        user.roles << admin_role
      end
    end

    trait :developer do
      after(:create) do |user|
        developer_role = user.tenant.roles.find_or_create_by!(name: 'developer')
        user.roles << developer_role
      end
    end

    trait :analyst do
      after(:create) do |user|
        analyst_role = user.tenant.roles.find_or_create_by!(name: 'analyst')
        user.roles << analyst_role
      end
    end

    trait :viewer do
      after(:create) do |user|
        viewer_role = user.tenant.roles.find_or_create_by!(name: 'viewer')
        user.roles << viewer_role
      end
    end
  end
end