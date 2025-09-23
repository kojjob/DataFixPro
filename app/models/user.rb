class User < ApplicationRecord
  # Use bcrypt for secure password
  has_secure_password

  # Associations
  belongs_to :tenant
  has_and_belongs_to_many :roles, join_table: :roles_users

  # Validations
  validates :email, presence: true,
                    uniqueness: { scope: :tenant_id, case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password, presence: true,
                       length: { minimum: 8 },
                       confirmation: true,
                       on: :create

  validates :password, length: { minimum: 8 },
                       confirmation: true,
                       allow_nil: true,
                       on: :update

  # Set default status
  attribute :status, :string, default: 'active'

  # Callbacks
  before_save :normalize_email

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :suspended, -> { where(status: 'suspended') }
  scope :with_role, ->(role_name) {
    joins(:roles).where(roles: { name: role_name })
  }

  # Check if user has a specific role
  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  # Check if user has a specific permission
  def has_permission?(resource, action)
    roles.any? do |role|
      role.has_permission?(resource, action)
    end
  end

  # Get full name or email
  def full_name
    name.present? ? name : email
  end

  # Check if user is admin
  def admin?
    has_role?('admin')
  end

  # Check if user is active
  def active?
    status == 'active'
  end

  # Check if user is inactive
  def inactive?
    status == 'inactive'
  end

  # Check if user is suspended
  def suspended?
    status == 'suspended'
  end

  private

  # Normalize email before saving
  def normalize_email
    if email.present?
      normalized = email.strip.downcase
      # Only set if the normalized email is valid
      self.email = normalized if normalized.match?(URI::MailTo::EMAIL_REGEXP)
    end
  end
end