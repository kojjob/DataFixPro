class Permission < ApplicationRecord
  has_and_belongs_to_many :roles

  validates :name, presence: true, uniqueness: true
  validates :resource, presence: true
  validates :action, presence: true

  # Predefined permissions
  SYSTEM_PERMISSIONS = {
    # User management
    manage_users: { resource: 'User', action: 'manage' },
    view_users: { resource: 'User', action: 'read' },

    # Data source management
    manage_data_sources: { resource: 'DataSource', action: 'manage' },
    view_data_sources: { resource: 'DataSource', action: 'read' },

    # Pipeline management
    manage_pipelines: { resource: 'Pipeline', action: 'manage' },
    view_pipelines: { resource: 'Pipeline', action: 'read' },
    run_pipelines: { resource: 'Pipeline', action: 'execute' },

    # Dashboard management
    manage_dashboards: { resource: 'Dashboard', action: 'manage' },
    view_dashboards: { resource: 'Dashboard', action: 'read' },

    # Tenant settings
    manage_tenant: { resource: 'Tenant', action: 'manage' },
    manage_billing: { resource: 'Billing', action: 'manage' },
  }.freeze

  scope :for_resource, ->(resource) { where(resource: resource) }
  scope :for_action, ->(action) { where(action: action) }

  def system_permission?
    SYSTEM_PERMISSIONS.keys.include?(name.to_sym)
  end

  def display_name
    name.humanize.titleize
  end
end