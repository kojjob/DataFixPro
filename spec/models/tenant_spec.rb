require 'rails_helper'

RSpec.describe Tenant, type: :model do
  describe 'associations' do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:data_sources).dependent(:destroy) }
    it { should have_many(:pipelines).dependent(:destroy) }
    it { should have_many(:dashboards).dependent(:destroy) }
    it { should have_many(:roles).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:tenant) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain) }
    it { should validate_presence_of(:api_key) }
    it { should validate_uniqueness_of(:api_key) }
    it { should validate_inclusion_of(:plan).in_array(%w[starter professional enterprise]) }
    it { should validate_inclusion_of(:status).in_array(%w[active suspended cancelled]) }
  end

  describe 'callbacks' do
    it 'generates api_key on create' do
      tenant = build(:tenant, api_key: nil)
      tenant.save!
      expect(tenant.api_key).to be_present
      expect(tenant.api_key.length).to eq(64)
    end

    it 'does not change api_key on update' do
      tenant = create(:tenant)
      original_key = tenant.api_key
      tenant.update!(name: 'Updated Name')
      expect(tenant.api_key).to eq(original_key)
    end
  end

  describe 'scopes' do
    let!(:active_tenant) { create(:tenant, status: 'active') }
    let!(:suspended_tenant) { create(:tenant, status: 'suspended') }
    let!(:cancelled_tenant) { create(:tenant, status: 'cancelled') }

    describe '.active' do
      it 'returns only active tenants' do
        expect(Tenant.active).to include(active_tenant)
        expect(Tenant.active).not_to include(suspended_tenant, cancelled_tenant)
      end
    end

    describe '.suspended' do
      it 'returns only suspended tenants' do
        expect(Tenant.suspended).to include(suspended_tenant)
        expect(Tenant.suspended).not_to include(active_tenant, cancelled_tenant)
      end
    end
  end

  describe '#active?' do
    it 'returns true for active tenants' do
      tenant = build(:tenant, status: 'active')
      expect(tenant.active?).to be true
    end

    it 'returns false for non-active tenants' do
      tenant = build(:tenant, status: 'suspended')
      expect(tenant.active?).to be false
    end
  end

  describe '#suspended?' do
    it 'returns true for suspended tenants' do
      tenant = build(:tenant, status: 'suspended')
      expect(tenant.suspended?).to be true
    end

    it 'returns false for non-suspended tenants' do
      tenant = build(:tenant, status: 'active')
      expect(tenant.suspended?).to be false
    end
  end

  describe 'multi-tenant isolation' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }
    let!(:user1) { create(:user, tenant: tenant1) }
    let!(:user2) { create(:user, tenant: tenant2) }

    it 'isolates users between tenants' do
      expect(tenant1.users).to include(user1)
      expect(tenant1.users).not_to include(user2)
      expect(tenant2.users).to include(user2)
      expect(tenant2.users).not_to include(user1)
    end
  end
end