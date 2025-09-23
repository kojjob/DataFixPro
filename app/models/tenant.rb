class Tenant < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: { case_sensitive: false }
  validates :subdomain, format: { with: /\A[a-z0-9-]+\z/, message: "is invalid" }
  validates :subdomain, exclusion: { in: %w[www app api admin dashboard], message: "is reserved" }
  validates :status, presence: true, inclusion: { in: %w[active inactive suspended] }
  validates :plan, presence: true, inclusion: { in: %w[starter professional enterprise] }
  validates :custom_domain, uniqueness: { allow_blank: true }

  # Associations
  has_many :users, dependent: :destroy
  has_many :data_sources, dependent: :destroy
  has_many :pipelines, dependent: :destroy
  has_many :dashboards, dependent: :destroy
  has_many :roles, dependent: :destroy

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_plan, ->(plan) { where(plan: plan) }

  # Callbacks
  before_validation :normalize_subdomain
  before_create :generate_api_key
  before_create :set_defaults
  after_create :create_default_roles
  after_create :create_default_settings

  # Plan limits
  PLAN_LIMITS = {
    starter: {
      users: 10,
      data_sources: 5,
      pipelines: 10,
      dashboards: 5,
      storage_gb: 10,
      api_calls_per_month: 10000
    },
    professional: {
      users: 50,
      data_sources: 25,
      pipelines: 100,
      dashboards: 50,
      storage_gb: 100,
      api_calls_per_month: 100000
    },
    enterprise: {
      users: Float::INFINITY,
      data_sources: Float::INFINITY,
      pipelines: Float::INFINITY,
      dashboards: Float::INFINITY,
      storage_gb: Float::INFINITY,
      api_calls_per_month: Float::INFINITY
    }
  }.freeze

  # Instance methods
  def active?
    status == 'active'
  end

  def suspend!
    update!(status: 'suspended', suspended_at: Time.current)
  end

  def reactivate!
    update!(status: 'active', suspended_at: nil)
  end

  def storage_usage
    # Calculate actual storage usage from various sources
    # This is a placeholder implementation
    0
  end

  def within_limits?(resource_type)
    current_count = case resource_type
                    when :users then users.count
                    when :data_sources then data_sources.count
                    when :pipelines then pipelines.count
                    when :dashboards then dashboards.count
                    else settings["current_#{resource_type}"] || 0
                    end

    limit = PLAN_LIMITS[plan.to_sym][resource_type]
    current_count < limit
  end

  def upgrade_plan!(new_plan)
    transaction do
      old_plan = plan
      self.plan = new_plan
      self.plan_changes ||= []
      self.plan_changes << {
        from: old_plan,
        to: new_plan,
        changed_at: Time.current.iso8601,
        changed_by: ActsAsTenant.current_tenant&.id
      }
      save!
    end
  end

  # Class methods
  def self.find_by_domain(domain)
    subdomain = domain.split('.').first
    find_by(subdomain: subdomain) || find_by(custom_domain: domain)
  end

  def self.create_with_owner!(params)
    transaction do
      tenant = create!(
        name: params[:name],
        subdomain: params[:subdomain],
        plan: params[:plan] || 'starter'
      )

      ActsAsTenant.with_tenant(tenant) do
        owner = User.create!(
          email: params[:owner_email],
          password: params[:owner_password] || SecureRandom.hex(16),
          name: params[:owner_name]
        )

        admin_role = tenant.roles.find_by(name: 'admin')
        owner.roles << admin_role if admin_role
      end

      tenant
    end
  end

  private

  def normalize_subdomain
    self.subdomain = subdomain.to_s.downcase.strip if subdomain.present?
  end

  def generate_api_key
    self.api_key = SecureRandom.hex(16)
  end

  def set_defaults
    self.plan ||= 'starter'
    self.status ||= 'active'
    self.settings ||= {}
  end

  def create_default_roles
    %w[admin developer analyst viewer].each do |role_name|
      roles.create!(name: role_name)
    end
  end

  def create_default_settings
    update!(settings: settings.merge(
      timezone: 'UTC',
      date_format: 'YYYY-MM-DD',
      currency: 'USD',
      language: 'en',
      current_users: 0,
      current_data_sources: 0,
      current_pipelines: 0,
      current_dashboards: 0
    ))
  end
end