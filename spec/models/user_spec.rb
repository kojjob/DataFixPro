require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should have_and_belong_to_many(:roles) }
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_one(:profile).dependent(:destroy) }
  end

  describe 'validations' do
    let(:tenant) { create(:tenant) }
    subject { build(:user, tenant: tenant) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).scoped_to(:tenant_id).case_insensitive }
    it { should validate_presence_of(:name) }

    context 'password validation' do
      it 'validates password length on create' do
        user = User.new(email: 'test@example.com', name: 'Test User', tenant: tenant, password: 'short')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 8 characters)')

        user.password = 'password123'
        expect(user).to be_valid
      end

      it 'allows nil password on update' do
        user = create(:user, tenant: tenant, password: 'password123')
        user.password = nil
        expect(user).to be_valid
      end
    end

    it 'validates email format' do
      user = build(:user, tenant: tenant, email: 'invalid')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')

      user.email = 'valid@example.com'
      expect(user).to be_valid
    end
  end

  describe 'callbacks' do
    describe 'before_save' do
      it 'normalizes email' do
        user = create(:user, email: '  TEST@Example.COM  ')
        expect(user.email).to eq('test@example.com')
      end
    end

    describe 'after_create' do
      let(:tenant) { create(:tenant) }

      it 'sends welcome email' do
        expect {
          create(:user, tenant: tenant)
        }.to enqueue_job(ActionMailer::MailDeliveryJob)
      end

      it 'creates user profile' do
        user = create(:user, tenant: tenant)
        expect(user.profile).to be_present
      end

      it 'assigns default role' do
        tenant = create(:tenant)
        user = create(:user, tenant: tenant)
        expect(user.roles.pluck(:name)).to include('viewer')
      end
    end
  end

  describe 'secure password' do
    let(:tenant) { create(:tenant) }
    let(:user) { create(:user, tenant: tenant, password: 'password123') }

    it 'authenticates with correct password' do
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'returns false with incorrect password' do
      expect(user.authenticate('wrong_password')).to be false
    end

    it 'stores password securely' do
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq('password123')
    end
  end

  describe 'multi-tenancy' do
    it 'acts as tenant scoped' do
      tenant1 = create(:tenant, subdomain: 'company1')
      tenant2 = create(:tenant, subdomain: 'company2')

      ActsAsTenant.with_tenant(tenant1) do
        create(:user, email: 'user@example.com', tenant: tenant1)
        expect(User.count).to eq(1)
      end

      ActsAsTenant.with_tenant(tenant2) do
        create(:user, email: 'user@example.com', tenant: tenant2)
        expect(User.count).to eq(1)
      end

      ActsAsTenant.without_tenant do
        expect(User.count).to eq(2)
      end
    end
  end

  describe 'scopes' do
    let(:tenant) { create(:tenant) }

    describe '.active' do
      it 'returns only active users' do
        active_user = create(:user, tenant: tenant, status: 'active')
        inactive_user = create(:user, tenant: tenant, status: 'inactive')
        suspended_user = create(:user, tenant: tenant, status: 'suspended')

        expect(User.active).to include(active_user)
        expect(User.active).not_to include(inactive_user, suspended_user)
      end
    end

    describe '.admins' do
      it 'returns users with admin role' do
        admin_role = tenant.roles.find_or_create_by!(name: 'admin')
        admin_user = create(:user, tenant: tenant, roles: [admin_role])
        regular_user = create(:user, tenant: tenant)

        expect(User.admins).to include(admin_user)
        expect(User.admins).not_to include(regular_user)
      end
    end

    describe '.recent' do
      it 'returns users created recently' do
        recent_user = create(:user, tenant: tenant, created_at: 2.days.ago)
        old_user = create(:user, tenant: tenant, created_at: 2.weeks.ago)

        expect(User.recent).to include(recent_user)
        expect(User.recent).not_to include(old_user)
      end
    end
  end

  describe 'instance methods' do
    let(:tenant) { create(:tenant) }
    let(:user) { create(:user, tenant: tenant) }

    describe '#full_name' do
      it 'returns concatenated first and last name' do
        user.update(first_name: 'John', last_name: 'Doe')
        expect(user.full_name).to eq('John Doe')
      end

      it 'handles missing names gracefully' do
        user.update(first_name: 'John', last_name: nil)
        expect(user.full_name).to eq('John')

        user.update(first_name: nil, last_name: 'Doe')
        expect(user.full_name).to eq('Doe')
      end
    end

    describe '#active?' do
      it 'returns true for active status' do
        user.status = 'active'
        expect(user.active?).to be true
      end

      it 'returns false for other statuses' do
        user.status = 'suspended'
        expect(user.active?).to be false
      end
    end

    describe '#suspend!' do
      it 'changes status to suspended' do
        user.suspend!
        expect(user.status).to eq('suspended')
        expect(user.suspended_at).to be_present
      end

      it 'logs out all sessions' do
        session1 = create(:session, user: user)
        session2 = create(:session, user: user)

        user.suspend!

        expect(session1.reload.active).to be false
        expect(session2.reload.active).to be false
      end
    end

    describe '#has_role?' do
      let(:admin_role) { tenant.roles.find_or_create_by!(name: 'admin') }

      it 'returns true if user has the role' do
        user.roles << admin_role
        expect(user.has_role?('admin')).to be true
      end

      it 'returns false if user does not have the role' do
        expect(user.has_role?('admin')).to be false
      end
    end

    describe '#add_role' do
      it 'adds a role to the user' do
        user.add_role('admin')
        expect(user.has_role?('admin')).to be true
      end

      it 'does not duplicate roles' do
        user.add_role('admin')
        user.add_role('admin')
        expect(user.roles.where(name: 'admin').count).to eq(1)
      end
    end

    describe '#remove_role' do
      it 'removes a role from the user' do
        user.add_role('admin')
        user.remove_role('admin')
        expect(user.has_role?('admin')).to be false
      end
    end

    describe '#can?' do
      it 'checks permission through roles' do
        admin_role = tenant.roles.find_or_create_by!(name: 'admin')
        permission = create(:permission, name: 'manage_users', role: admin_role)
        user.roles << admin_role

        expect(user.can?('manage_users')).to be true
        expect(user.can?('manage_billing')).to be false
      end
    end
  end

  describe 'session management' do
    let(:tenant) { create(:tenant) }
    let(:user) { create(:user, tenant: tenant) }

    describe '#create_session' do
      it 'creates a new session with tracking info' do
        session = user.create_session(
          ip_address: '192.168.1.1',
          user_agent: 'Mozilla/5.0',
          device_type: 'desktop'
        )

        expect(session).to be_persisted
        expect(session.ip_address).to eq('192.168.1.1')
        expect(session.user_agent).to eq('Mozilla/5.0')
        expect(session.device_type).to eq('desktop')
        expect(session.active).to be true
      end

      it 'generates a secure token' do
        session = user.create_session(ip_address: '127.0.0.1')
        expect(session.token).to be_present
        expect(session.token.length).to be >= 32
      end
    end

    describe '#active_sessions' do
      it 'returns only active sessions' do
        active_session = create(:session, user: user, active: true)
        inactive_session = create(:session, user: user, active: false)

        expect(user.active_sessions).to include(active_session)
        expect(user.active_sessions).not_to include(inactive_session)
      end
    end

    describe '#logout_all_sessions' do
      it 'deactivates all user sessions' do
        session1 = create(:session, user: user, active: true)
        session2 = create(:session, user: user, active: true)

        user.logout_all_sessions

        expect(session1.reload.active).to be false
        expect(session2.reload.active).to be false
      end
    end
  end

  describe 'password reset' do
    let(:tenant) { create(:tenant) }
    let(:user) { create(:user, tenant: tenant) }

    describe '#generate_password_reset_token!' do
      it 'generates a secure reset token' do
        user.generate_password_reset_token!
        expect(user.password_reset_token).to be_present
        expect(user.password_reset_sent_at).to be_present
      end

      it 'invalidates previous tokens' do
        old_token = user.generate_password_reset_token!
        new_token = user.generate_password_reset_token!
        expect(new_token).not_to eq(old_token)
      end
    end

    describe '#password_reset_expired?' do
      it 'returns true if token is older than 2 hours' do
        user.password_reset_sent_at = 3.hours.ago
        expect(user.password_reset_expired?).to be true
      end

      it 'returns false if token is recent' do
        user.password_reset_sent_at = 30.minutes.ago
        expect(user.password_reset_expired?).to be false
      end
    end
  end
end