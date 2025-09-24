require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should have_and_belong_to_many(:users) }
  end

  describe 'validations' do
    subject { build(:role) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:tenant_id).case_insensitive }

    it 'validates name format' do
      role = build(:role, name: 'Admin Role!')
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include('only allows letters, numbers, underscores and hyphens')
    end

    it 'accepts valid name formats' do
      valid_names = ['admin', 'super_admin', 'data-engineer', 'user123']
      valid_names.each do |name|
        role = build(:role, name: name)
        expect(role).to be_valid
      end
    end
  end

  describe 'callbacks' do
    it 'normalizes name before saving' do
      role = create(:role, name: '  ADMIN  ')
      expect(role.reload.name).to eq('admin')
    end

    it 'initializes permissions as empty hash if nil' do
      role = create(:role, permissions: nil)
      expect(role.permissions).to eq({})
    end
  end

  describe 'scopes' do
    let(:tenant) { create(:tenant) }
    let!(:admin_role) { create(:role, name: 'admin', tenant: tenant) }
    let!(:editor_role) { create(:role, name: 'editor', tenant: tenant) }
    let!(:viewer_role) { create(:role, name: 'viewer', tenant: tenant) }

    describe '.by_name' do
      it 'orders roles alphabetically by name' do
        expect(Role.by_name.pluck(:name)).to eq(['admin', 'editor', 'viewer'])
      end
    end

    describe '.system_roles' do
      let!(:custom_role) { create(:role, name: 'custom_role', tenant: tenant) }

      it 'returns only system-defined roles' do
        system_roles = Role.system_roles
        expect(system_roles.pluck(:name)).to include('admin', 'viewer')
        expect(system_roles.pluck(:name)).not_to include('custom_role')
      end
    end
  end

  describe '#add_permission' do
    let(:role) { create(:role) }

    it 'adds a new permission for a resource' do
      role.add_permission('pipelines', 'read')
      expect(role.permissions['pipelines']).to include('read')
    end

    it 'adds multiple permissions for a resource' do
      role.add_permission('pipelines', 'read')
      role.add_permission('pipelines', 'write')
      expect(role.permissions['pipelines']).to match_array(['read', 'write'])
    end

    it 'does not duplicate permissions' do
      role.add_permission('pipelines', 'read')
      role.add_permission('pipelines', 'read')
      expect(role.permissions['pipelines']).to eq(['read'])
    end
  end

  describe '#remove_permission' do
    let(:role) { create(:role, permissions: { 'pipelines' => ['read', 'write', 'delete'] }) }

    it 'removes a specific permission' do
      role.remove_permission('pipelines', 'write')
      expect(role.permissions['pipelines']).to match_array(['read', 'delete'])
    end

    it 'removes the resource key when all permissions are removed' do
      role.remove_permission('pipelines', 'read')
      role.remove_permission('pipelines', 'write')
      role.remove_permission('pipelines', 'delete')
      expect(role.permissions).not_to have_key('pipelines')
    end
  end

  describe '#has_permission?' do
    let(:role) { create(:role, permissions: { 'pipelines' => ['read', 'write'], 'users' => ['read'] }) }

    it 'returns true when permission exists' do
      expect(role.has_permission?('pipelines', 'read')).to be true
      expect(role.has_permission?('pipelines', 'write')).to be true
      expect(role.has_permission?('users', 'read')).to be true
    end

    it 'returns false when permission does not exist' do
      expect(role.has_permission?('pipelines', 'delete')).to be false
      expect(role.has_permission?('users', 'write')).to be false
      expect(role.has_permission?('dashboards', 'read')).to be false
    end
  end

  describe '#set_permissions' do
    let(:role) { create(:role) }

    it 'replaces all permissions' do
      new_permissions = {
        'pipelines' => ['read', 'write'],
        'dashboards' => ['read']
      }
      role.set_permissions(new_permissions)
      expect(role.permissions).to eq(new_permissions)
    end

    it 'clears permissions when given empty hash' do
      role.permissions = { 'pipelines' => ['read'] }
      role.set_permissions({})
      expect(role.permissions).to eq({})
    end
  end

  describe '#admin?' do
    it 'returns true for admin role' do
      role = build(:role, name: 'admin')
      expect(role.admin?).to be true
    end

    it 'returns false for non-admin roles' do
      role = build(:role, name: 'editor')
      expect(role.admin?).to be false
    end
  end

  describe '#system_role?' do
    it 'returns true for system-defined roles' do
      %w[admin editor viewer].each do |name|
        role = build(:role, name: name)
        expect(role.system_role?).to be true
      end
    end

    it 'returns false for custom roles' do
      role = build(:role, name: 'custom_role')
      expect(role.system_role?).to be false
    end
  end

  describe 'permission constants' do
    it 'defines available permissions' do
      expect(Role::PERMISSIONS).to be_a(Hash)
      expect(Role::PERMISSIONS).to include(
        'pipelines' => array_including('read', 'write', 'delete', 'execute'),
        'data_sources' => array_including('read', 'write', 'delete', 'test'),
        'dashboards' => array_including('read', 'write', 'delete', 'share'),
        'users' => array_including('read', 'write', 'delete', 'invite'),
        'roles' => array_including('read', 'write', 'delete', 'assign')
      )
    end

    it 'defines system roles' do
      expect(Role::SYSTEM_ROLES).to include('admin', 'editor', 'viewer')
    end
  end
end