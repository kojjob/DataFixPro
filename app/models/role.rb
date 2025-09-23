class Role < ApplicationRecord
  # Constants
  SYSTEM_ROLES = %w[admin editor viewer].freeze

  PERMISSIONS = {
    'pipelines' => %w[read write delete execute],
    'data_sources' => %w[read write delete test],
    'dashboards' => %w[read write delete share],
    'users' => %w[read write delete invite],
    'roles' => %w[read write delete assign]
  }.freeze

  # Associations
  belongs_to :tenant
  has_and_belongs_to_many :users, join_table: :roles_users

  # Validations
  validates :name, presence: true,
                   uniqueness: { scope: :tenant_id, case_sensitive: false }

  validate :name_format_after_normalization

  # Callbacks
  before_save :normalize_name
  before_save :ensure_permissions_hash

  # Scopes
  scope :by_name, -> { order(:name) }
  scope :system_roles, -> { where(name: SYSTEM_ROLES) }
  scope :custom_roles, -> { where.not(name: SYSTEM_ROLES) }

  # Add a permission to the role
  def add_permission(resource, action)
    self.permissions ||= {}
    self.permissions[resource] ||= []
    unless self.permissions[resource].include?(action)
      self.permissions[resource] << action
      save!
    end
  end

  # Remove a permission from the role
  def remove_permission(resource, action)
    return unless permissions && permissions[resource]

    permissions[resource].delete(action)
    permissions.delete(resource) if permissions[resource].empty?
    save!
  end

  # Check if role has a specific permission
  def has_permission?(resource, action)
    return false unless permissions && permissions[resource]
    permissions[resource].include?(action)
  end

  # Set all permissions at once
  def set_permissions(new_permissions)
    self.permissions = new_permissions
    save!
  end

  # Check if this is an admin role
  def admin?
    name == 'admin'
  end

  # Check if this is a system-defined role
  def system_role?
    SYSTEM_ROLES.include?(name)
  end

  private

  # Normalize role name
  def normalize_name
    self.name = name.downcase.strip.gsub(/\s+/, '_') if name.present?
  end

  # Validate name format after normalization
  def name_format_after_normalization
    if name.present? && !name.match?(/\A[a-z0-9_\-]+\z/i)
      errors.add(:name, 'only allows letters, numbers, underscores and hyphens')
    end
  end

  # Ensure permissions is always a hash
  def ensure_permissions_hash
    self.permissions ||= {}
  end
end