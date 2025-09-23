FactoryBot.define do
  factory :permission do
    sequence(:name) { |n| "permission_#{n}" }
    resource { 'TestResource' }
    action { 'read' }
  end
end