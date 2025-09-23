FactoryBot.define do
  factory :session do
    association :user
    token { SecureRandom.hex(32) }
    ip_address { '127.0.0.1' }
    user_agent { 'Mozilla/5.0' }
    device_type { 'desktop' }
    active { true }
  end
end