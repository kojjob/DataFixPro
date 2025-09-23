class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :lockable

  # Associations
  belongs_to :tenant
  has_and_belongs_to_many :roles
  has_many :sessions, dependent: :destroy
  has_one :profile, dependent: :destroy

  # Validations
  validates :email, uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :name, presence: true

  # Multi-tenancy
  acts_as_tenant :tenant

  # Callbacks
  before_save :normalize_email
  after_create :send_welcome_email
  after_create :create_default_profile
  after_create :assign_default_role

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :admins, -> { joins(:roles).where(roles: { name: 'admin' }) }
  scope :recent, -> { where('created_at > ?', 1.week.ago) }

  # Instance methods
  def full_name
    [first_name, last_name].compact.join(' ').presence || name
  end

  def active?
    status == 'active'
  end

  def suspend!
    update!(status: 'suspended', suspended_at: Time.current)
    logout_all_sessions
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def add_role(role_name)
    role = tenant.roles.find_or_create_by!(name: role_name)
    roles << role unless roles.include?(role)
  end

  def remove_role(role_name)
    role = tenant.roles.find_by(name: role_name)
    roles.delete(role) if role
  end

  def can?(permission_name)
    roles.joins(:permissions).exists?(permissions: { name: permission_name })
  end

  # Session management
  def create_session(ip_address:, user_agent: nil, device_type: nil)
    sessions.create!(
      token: SecureRandom.hex(32),
      ip_address: ip_address,
      user_agent: user_agent,
      device_type: device_type,
      active: true
    )
  end

  def active_sessions
    sessions.where(active: true)
  end

  def logout_all_sessions
    sessions.update_all(active: false)
  end


  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
  end

  def create_default_profile
    build_profile.save if profile.nil?
  end

  def assign_default_role
    viewer_role = tenant.roles.find_or_create_by!(name: 'viewer')
    roles << viewer_role unless roles.any?
  end
end