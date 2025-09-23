FactoryBot.define do
  factory :user do
    tenant
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { 'password123' }
    password_confirmation { 'password123' }
    status { 'active' }

    trait :admin do
      after(:create) do |user|
        admin_role = user.tenant.roles.find_or_create_by!(name: 'admin') do |role|
          role.permissions = {
            'pipelines' => ['read', 'write', 'delete', 'execute'],
            'data_sources' => ['read', 'write', 'delete', 'test'],
            'dashboards' => ['read', 'write', 'delete', 'share'],
            'users' => ['read', 'write', 'delete', 'invite'],
            'roles' => ['read', 'write', 'delete', 'assign']
          }
        end
        user.roles << admin_role unless user.roles.include?(admin_role)
      end
    end

    trait :editor do
      after(:create) do |user|
        editor_role = user.tenant.roles.find_or_create_by!(name: 'editor') do |role|
          role.permissions = {
            'pipelines' => ['read', 'write'],
            'data_sources' => ['read', 'write'],
            'dashboards' => ['read', 'write'],
            'users' => ['read'],
            'roles' => ['read']
          }
        end
        user.roles << editor_role unless user.roles.include?(editor_role)
      end
    end

    trait :viewer do
      after(:create) do |user|
        viewer_role = user.tenant.roles.find_or_create_by!(name: 'viewer') do |role|
          role.permissions = {
            'pipelines' => ['read'],
            'data_sources' => ['read'],
            'dashboards' => ['read'],
            'users' => ['read'],
            'roles' => ['read']
          }
        end
        user.roles << viewer_role unless user.roles.include?(viewer_role)
      end
    end

    trait :inactive do
      status { 'inactive' }
    end

    trait :suspended do
      status { 'suspended' }
    end
  end
end