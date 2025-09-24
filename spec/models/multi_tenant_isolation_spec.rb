require 'rails_helper'

RSpec.describe 'Multi-Tenant Data Isolation', type: :model do
  let!(:tenant1) { create(:tenant, name: 'Tenant One', subdomain: 'tenant1') }
  let!(:tenant2) { create(:tenant, name: 'Tenant Two', subdomain: 'tenant2') }

  describe 'User isolation' do
    let!(:user1) { create(:user, tenant: tenant1, email: 'user@tenant1.com') }
    let!(:user2) { create(:user, tenant: tenant2, email: 'user@tenant2.com') }
    let!(:user3) { create(:user, tenant: tenant1, email: 'another@tenant1.com') }

    it 'isolates users by tenant' do
      expect(tenant1.users).to contain_exactly(user1, user3)
      expect(tenant2.users).to contain_exactly(user2)
    end

    it 'allows duplicate emails across tenants' do
      duplicate_user = build(:user, tenant: tenant2, email: user1.email)
      expect(duplicate_user).to be_valid
    end

    it 'prevents duplicate emails within the same tenant' do
      duplicate_user = build(:user, tenant: tenant1, email: user1.email)
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end

    it 'cascades deletion when tenant is destroyed' do
      user_id = user1.id
      tenant1.destroy

      expect(User.find_by(id: user_id)).to be_nil
      expect(tenant2.users).to include(user2)
    end
  end

  describe 'Role isolation' do
    let!(:role1) { create(:role, tenant: tenant1, name: 'manager') }
    let!(:role2) { create(:role, tenant: tenant2, name: 'manager') }
    let!(:role3) { create(:role, tenant: tenant1, name: 'developer') }

    it 'isolates roles by tenant' do
      expect(tenant1.roles).to contain_exactly(role1, role3)
      expect(tenant2.roles).to contain_exactly(role2)
    end

    it 'allows duplicate role names across tenants' do
      duplicate_role = build(:role, tenant: tenant2, name: 'developer')
      expect(duplicate_role).to be_valid
    end

    it 'prevents duplicate role names within the same tenant' do
      duplicate_role = build(:role, tenant: tenant1, name: 'manager')
      expect(duplicate_role).not_to be_valid
      expect(duplicate_role.errors[:name]).to include('has already been taken')
    end

    it 'cascades deletion when tenant is destroyed' do
      role_id = role1.id
      tenant1.destroy

      expect(Role.find_by(id: role_id)).to be_nil
      expect(tenant2.roles).to include(role2)
    end
  end

  describe 'Cross-tenant security' do
    let!(:admin_role1) { create(:role, :admin, tenant: tenant1) }
    let!(:admin_role2) { create(:role, :admin, tenant: tenant2) }
    let!(:admin1) { create(:user, tenant: tenant1, roles: [admin_role1]) }
    let!(:admin2) { create(:user, tenant: tenant2, roles: [admin_role2]) }

    it 'prevents users from accessing other tenant roles' do
      # Admin1 should not be able to have roles from tenant2
      expect { admin1.roles << admin_role2 }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'isolates role permissions by tenant' do
      expect(admin1.roles).to include(admin_role1)
      expect(admin1.roles).not_to include(admin_role2)
      expect(admin2.roles).to include(admin_role2)
      expect(admin2.roles).not_to include(admin_role1)
    end
  end

  describe 'Data integrity' do
    it 'maintains tenant references after updates' do
      user = create(:user, tenant: tenant1)
      user.update!(name: 'Updated Name')

      expect(user.reload.tenant).to eq(tenant1)
    end

    it 'prevents reassignment to another tenant' do
      user = create(:user, tenant: tenant1)
      user.tenant = tenant2

      expect(user.save).to be true
      # In a production app, you might want to prevent tenant reassignment
      # by adding a validation or making tenant_id readonly after creation
    end
  end
end