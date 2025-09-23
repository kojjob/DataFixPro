require 'rails_helper'

RSpec.describe Tenant, type: :model do
  describe 'validations' do
    subject { Tenant.new(name: 'Test', subdomain: 'test') }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain).case_insensitive }
    it { should validate_presence_of(:status) }

    it 'validates subdomain format' do
      tenant = Tenant.new(name: 'Test', subdomain: 'test-123')
      tenant.valid?
      expect(tenant).to be_valid

      tenant.subdomain = 'test_123'
      tenant.valid?
      expect(tenant).not_to be_valid
      expect(tenant.errors[:subdomain]).to include('is invalid')

      tenant.subdomain = 'TeSt'  # Uppercase should be normalized to lowercase
      tenant.valid?
      expect(tenant.subdomain).to eq('test')  # Check normalization
      expect(tenant).to be_valid
    end

    it 'validates reserved subdomains' do
      %w[www app api admin dashboard].each do |subdomain|
        tenant = Tenant.new(name: 'Test', subdomain: subdomain)
        expect(tenant).not_to be_valid
        expect(tenant.errors[:subdomain]).to include('is reserved')
      end
    end
  end

  describe 'associations' do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:data_sources).dependent(:destroy) }
    it { should have_many(:pipelines).dependent(:destroy) }
    it { should have_many(:dashboards).dependent(:destroy) }
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active tenants' do
        active_tenant = Tenant.create!(name: 'Active', subdomain: 'active', status: 'active')
        inactive_tenant = Tenant.create!(name: 'Inactive', subdomain: 'inactive', status: 'inactive')
        suspended_tenant = Tenant.create!(name: 'Suspended', subdomain: 'suspended', status: 'suspended')

        expect(Tenant.active).to include(active_tenant)
        expect(Tenant.active).not_to include(inactive_tenant, suspended_tenant)
      end
    end

    describe '.by_plan' do
      it 'returns tenants by plan type' do
        starter = Tenant.create!(name: 'Starter', subdomain: 'starter', plan: 'starter')
        professional = Tenant.create!(name: 'Pro', subdomain: 'pro', plan: 'professional')
        enterprise = Tenant.create!(name: 'Enterprise', subdomain: 'enterprise', plan: 'enterprise')

        expect(Tenant.by_plan('starter')).to include(starter)
        expect(Tenant.by_plan('professional')).to include(professional)
        expect(Tenant.by_plan('enterprise')).to include(enterprise)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'normalizes subdomain' do
        tenant = Tenant.new(name: 'Test', subdomain: ' TeSt-123 ')
        tenant.valid?
        expect(tenant.subdomain).to eq('test-123')
      end
    end

    describe 'before_create' do
      it 'generates api_key' do
        tenant = Tenant.create!(name: 'Test', subdomain: 'test')
        expect(tenant.api_key).to be_present
        expect(tenant.api_key.length).to eq(32)
      end

      it 'sets default plan' do
        tenant = Tenant.create!(name: 'Test', subdomain: 'test')
        expect(tenant.plan).to eq('starter')
      end

      it 'sets default status' do
        tenant = Tenant.create!(name: 'Test', subdomain: 'test')
        expect(tenant.status).to eq('active')
      end
    end

    describe 'after_create' do
      it 'creates default roles' do
        tenant = Tenant.create!(name: 'Test', subdomain: 'test')
        expect(tenant.roles.pluck(:name)).to match_array(['admin', 'developer', 'analyst', 'viewer'])
      end

      it 'creates default settings' do
        tenant = Tenant.create!(name: 'Test', subdomain: 'test')
        expect(tenant.settings).to be_present
        expect(tenant.settings['timezone']).to eq('UTC')
        expect(tenant.settings['date_format']).to eq('YYYY-MM-DD')
      end
    end
  end

  describe 'instance methods' do
    let(:tenant) { Tenant.create!(name: 'Test', subdomain: 'test') }

    describe '#active?' do
      it 'returns true for active status' do
        tenant.status = 'active'
        expect(tenant.active?).to be true
      end

      it 'returns false for other statuses' do
        tenant.status = 'inactive'
        expect(tenant.active?).to be false
      end
    end

    describe '#suspend!' do
      it 'changes status to suspended' do
        tenant.suspend!
        expect(tenant.status).to eq('suspended')
      end

      it 'sets suspended_at timestamp' do
        tenant.suspend!
        expect(tenant.suspended_at).to be_present
      end
    end

    describe '#reactivate!' do
      it 'changes status to active' do
        tenant.status = 'suspended'
        tenant.reactivate!
        expect(tenant.status).to eq('active')
      end

      it 'clears suspended_at timestamp' do
        tenant.suspended_at = Time.current
        tenant.reactivate!
        expect(tenant.suspended_at).to be_nil
      end
    end

    describe '#storage_usage' do
      it 'calculates total storage used' do
        # This would connect to actual storage services
        expect(tenant.storage_usage).to be_a(Numeric)
      end
    end

    describe '#within_limits?' do
      context 'starter plan' do
        before { tenant.plan = 'starter' }

        it 'checks against starter limits' do
          # Create users to test against limits
          9.times { User.create!(tenant: tenant, email: Faker::Internet.email, password: 'password123') }
          expect(tenant.within_limits?(:users)).to be true

          # Creating 10th user should exceed limit
          User.create!(tenant: tenant, email: 'user10@test.com', password: 'password123')
          expect(tenant.within_limits?(:users)).to be false
        end
      end
    end

    describe '#upgrade_plan!' do
      it 'upgrades from starter to professional' do
        tenant.plan = 'starter'
        tenant.upgrade_plan!('professional')
        expect(tenant.plan).to eq('professional')
      end

      it 'records plan change history' do
        expect {
          tenant.upgrade_plan!('professional')
        }.to change { tenant.plan_changes.count }.by(1)
      end
    end
  end

  describe 'class methods' do
    describe '.find_by_domain' do
      it 'finds tenant by full domain' do
        tenant = Tenant.create!(name: 'Test', subdomain: 'test')
        found = Tenant.find_by_domain('test.datafixpro.com')
        expect(found).to eq(tenant)
      end

      it 'finds tenant by custom domain' do
        tenant = Tenant.create!(name: 'Test', subdomain: 'test', custom_domain: 'analytics.company.com')
        found = Tenant.find_by_domain('analytics.company.com')
        expect(found).to eq(tenant)
      end
    end

    describe '.create_with_owner!' do
      it 'creates tenant with owner user' do
        tenant = Tenant.create_with_owner!(
          name: 'New Company',
          subdomain: 'newco',
          owner_email: 'owner@newco.com',
          owner_name: 'John Doe'
        )

        expect(tenant).to be_persisted
        expect(tenant.users.count).to eq(1)

        owner = tenant.users.first
        expect(owner.email).to eq('owner@newco.com')
        expect(owner.roles.first.name).to eq('admin')
      end
    end
  end

  describe 'multi-tenancy' do
    it 'isolates data between tenants' do
      tenant1 = Tenant.create!(name: 'Tenant 1', subdomain: 'tenant1')
      tenant2 = Tenant.create!(name: 'Tenant 2', subdomain: 'tenant2')

      ActsAsTenant.with_tenant(tenant1) do
        User.create!(email: 'user@tenant1.com', password: 'password123')
        expect(User.count).to eq(1)
      end

      ActsAsTenant.with_tenant(tenant2) do
        expect(User.count).to eq(0)
        User.create!(email: 'user@tenant2.com', password: 'password123')
        expect(User.count).to eq(1)
      end

      ActsAsTenant.with_tenant(tenant1) do
        expect(User.count).to eq(1)
        expect(User.first.email).to eq('user@tenant1.com')
      end
    end
  end
end