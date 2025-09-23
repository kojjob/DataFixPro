class Session < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :ip_address, presence: true

  scope :active, -> { where(active: true) }
  scope :expired, -> { where('last_activity_at < ?', 30.minutes.ago) }

  before_validation :generate_token, on: :create

  def expire!
    update!(active: false)
  end

  def refresh!
    update!(last_activity_at: Time.current)
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end