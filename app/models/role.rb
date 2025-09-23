class Role < ApplicationRecord
  belongs_to :tenant
  has_and_belongs_to_many :users
  has_and_belongs_to_many :permissions

  validates :name, presence: true, uniqueness: { scope: :tenant_id }

  acts_as_tenant :tenant

  # Predefined roles
  SYSTEM_ROLES = %w[admin developer analyst viewer].freeze

  scope :system_roles, -> { where(name: SYSTEM_ROLES) }
  scope :custom_roles, -> { where.not(name: SYSTEM_ROLES) }

  def system_role?
    SYSTEM_ROLES.include?(name)
  end

  def add_permission(permission_name)
    permission = Permission.find_or_create_by!(
      name: permission_name,
      resource: permission_name.split('_').first.capitalize,
      action: permission_name.split('_').last
    )
    permissions << permission unless permissions.include?(permission)
  end

  def remove_permission(permission_name)
    permission = permissions.find_by(name: permission_name)
    permissions.delete(permission) if permission
  end
end