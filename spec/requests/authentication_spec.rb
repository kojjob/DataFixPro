require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant, password: 'password123') }

  describe 'User authentication' do
    it 'successfully authenticates with correct password' do
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'fails authentication with incorrect password' do
      expect(user.authenticate('wrongpassword')).to be_falsey
    end
  end

  describe 'Multi-tenant isolation' do
    let(:tenant2) { create(:tenant) }
    let(:user2) { create(:user, tenant: tenant2, email: 'same@example.com') }

    it 'allows same email in different tenants' do
      user1 = create(:user, tenant: tenant, email: 'unique@example.com')
      user2 = create(:user, tenant: tenant2, email: 'unique@example.com')

      expect(user1).to be_valid
      expect(user2).to be_valid
      expect(user1.tenant_id).not_to eq(user2.tenant_id)
    end

    it 'isolates user data by tenant' do
      users_tenant1 = tenant.users
      users_tenant2 = tenant2.users

      expect(users_tenant1).not_to include(user2)
      expect(users_tenant2).not_to include(user)
    end
  end

  describe 'Role-based access control' do
    let(:admin_role) { create(:role, :admin, tenant: tenant) }
    let(:viewer_role) { create(:role, :viewer, tenant: tenant) }
    let(:admin_user) { create(:user, tenant: tenant, roles: [admin_role]) }
    let(:viewer_user) { create(:user, tenant: tenant, roles: [viewer_role]) }

    it 'assigns roles correctly' do
      expect(admin_user.has_role?('admin')).to be true
      expect(viewer_user.has_role?('viewer')).to be true
      expect(viewer_user.has_role?('admin')).to be false
    end

    it 'checks permissions correctly' do
      expect(admin_user.has_permission?('pipelines', 'delete')).to be true
      expect(viewer_user.has_permission?('pipelines', 'delete')).to be false
      expect(viewer_user.has_permission?('pipelines', 'read')).to be true
    end
  end
end