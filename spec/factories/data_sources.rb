FactoryBot.define do
  factory :data_source do
    tenant
    sequence(:name) { |n| "Data Source #{n}" }
    connection_type { 'postgresql' }
    host { 'localhost' }
    port { 5432 }
    database_name { 'test_db' }
    username { 'test_user' }
    password { 'test_password' }
    connection_status { 'disconnected' }
    connection_errors { [] }
    connection_options { {} }

    trait :mysql do
      connection_type { 'mysql' }
      port { 3306 }
    end

    trait :connected do
      connection_status { 'connected' }
      last_connected_at { Time.current }
    end

    trait :failed do
      connection_status { 'failed' }
      connection_errors do
        [{ 'error' => 'Connection failed', 'timestamp' => Time.current.iso8601 }]
      end
    end

    trait :with_ssl do
      connection_options { { 'sslmode' => 'require' } }
    end
  end
end