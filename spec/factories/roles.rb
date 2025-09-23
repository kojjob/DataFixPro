FactoryBot.define do
  factory :role do
    tenant
    sequence(:name) { |n| "role_#{n}" }
    permissions { {} }

    trait :admin do
      name { 'admin' }
      permissions do
        {
          'pipelines' => ['read', 'write', 'delete', 'execute'],
          'data_sources' => ['read', 'write', 'delete', 'test'],
          'dashboards' => ['read', 'write', 'delete', 'share'],
          'users' => ['read', 'write', 'delete', 'invite'],
          'roles' => ['read', 'write', 'delete', 'assign']
        }
      end
    end

    trait :editor do
      name { 'editor' }
      permissions do
        {
          'pipelines' => ['read', 'write'],
          'data_sources' => ['read', 'write'],
          'dashboards' => ['read', 'write'],
          'users' => ['read'],
          'roles' => ['read']
        }
      end
    end

    trait :viewer do
      name { 'viewer' }
      permissions do
        {
          'pipelines' => ['read'],
          'data_sources' => ['read'],
          'dashboards' => ['read'],
          'users' => ['read'],
          'roles' => ['read']
        }
      end
    end

    trait :custom do
      sequence(:name) { |n| "custom_role_#{n}" }
      permissions do
        {
          'pipelines' => ['read', 'execute'],
          'dashboards' => ['read', 'write']
        }
      end
    end
  end
end