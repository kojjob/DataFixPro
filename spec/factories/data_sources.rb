FactoryBot.define do
  factory :data_source do
    association :tenant
    sequence(:name) { |n| "Data Source #{n}" }
    connector { {} }
  end
end