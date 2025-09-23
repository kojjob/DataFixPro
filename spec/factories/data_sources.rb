FactoryBot.define do
  factory :data_source do
    association :tenant
    sequence(:name) { |n| "Data Source #{n}" }
    connection_type { "postgresql" }
    host { "localhost" }
    database_name { "test_db" }
    username { "test_user" }
    password { "test_password" }
    port { 5432 }
    connection_status { "connected" }
    connection_options { {} }
    connection_errors { [] }
  end
end
