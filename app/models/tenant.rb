class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :data_sources, dependent: :destroy
  has_many :pipelines, dependent: :destroy
  has_many :dashboards, dependent: :destroy
  has_many :roles, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true
  validates :api_key, presence: true, uniqueness: true
  validates :plan, inclusion: { in: %w[starter professional enterprise] }
  validates :status, inclusion: { in: %w[active suspended cancelled] }

  before_validation :generate_api_key, on: :create

  scope :active, -> { where(status: 'active') }
  scope :suspended, -> { where(status: 'suspended') }

  def active?
    status == 'active'
  end

  def suspended?
    status == 'suspended'
  end

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end
end