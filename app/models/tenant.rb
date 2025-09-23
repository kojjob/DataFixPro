class Tenant < ApplicationRecord
  # Associations
  has_many :users, dependent: :destroy
  has_many :data_sources, dependent: :destroy
  has_many :pipelines, dependent: :destroy
  has_many :dashboards, dependent: :destroy
  has_many :roles, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true
  validates :api_key, presence: true, uniqueness: true
  validates :plan, inclusion: { in: %w[starter professional enterprise] }
  validates :status, inclusion: { in: %w[active suspended cancelled] }

  # Callbacks
  before_validation :generate_api_key, on: :create

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :suspended, -> { where(status: 'suspended') }
  scope :cancelled, -> { where(status: 'cancelled') }

  # Check if tenant is active
  def active?
    status == 'active'
  end

  # Check if tenant is suspended
  def suspended?
    status == 'suspended'
  end

  # Check if tenant is cancelled
  def cancelled?
    status == 'cancelled'
  end

  # Suspend the tenant
  def suspend!
    update!(status: 'suspended', suspended_at: Time.current)
  end

  # Reactivate the tenant
  def reactivate!
    update!(status: 'active', suspended_at: nil)
  end

  # Cancel the tenant
  def cancel!
    update!(status: 'cancelled')
  end

  private

  # Generate a unique API key
  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end
end