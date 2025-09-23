require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should have_and_belong_to_many(:roles) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).scoped_to(:tenant_id).case_insensitive }
    it { should validate_presence_of(:password).on(:create) }
    it { should validate_length_of(:password).is_at_least(8).on(:create) }
    it { should validate_confirmation_of(:password) }

    it 'validates email format' do
      user = build(:user, email: 'invalid-email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'accepts valid email formats' do
      valid_emails = ['user@example.com', 'user+tag@example.co.uk', 'user_name@example.org']
      valid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).to be_valid
      end
    end
  end

  describe 'secure password' do
    let(:user) { build(:user, password: 'password123', password_confirmation: 'password123') }

    it 'encrypts password using bcrypt' do
      user.save!
      expect(user.password_digest).not_to eq('password123')
      expect(user.password_digest).to be_present
    end

    it 'authenticates with correct password' do
      user.save!
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user.save!
      expect(user.authenticate('wrongpassword')).to be_falsey
    end
  end

  describe 'multi-tenancy' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }

    it 'allows same email in different tenants' do
      user1 = create(:user, email: 'same@example.com', tenant: tenant1)
      user2 = build(:user, email: 'same@example.com', tenant: tenant2)
      expect(user2).to be_valid
    end

    it 'prevents duplicate emails within same tenant' do
      create(:user, email: 'duplicate@example.com', tenant: tenant1)
      user2 = build(:user, email: 'duplicate@example.com', tenant: tenant1)
      expect(user2).not_to be_valid
      expect(user2.errors[:email]).to include('has already been taken')
    end
  end

  describe 'callbacks' do
    it 'normalizes email before saving' do
      user = create(:user, email: '  TEST@EXAMPLE.COM  ')
      expect(user.reload.email).to eq('test@example.com')
    end
  end

  describe 'scopes' do
    let(:tenant) { create(:tenant) }
    let!(:admin_role) { create(:role, name: 'admin', tenant: tenant) }
    let!(:user_role) { create(:role, name: 'user', tenant: tenant) }
    let!(:admin_user) { create(:user, tenant: tenant, roles: [admin_role]) }
    let!(:regular_user) { create(:user, tenant: tenant, roles: [user_role]) }
    let!(:no_role_user) { create(:user, tenant: tenant) }

    it 'returns users with admin role' do
      expect(User.with_role('admin')).to include(admin_user)
      expect(User.with_role('admin')).not_to include(regular_user, no_role_user)
    end

    it 'returns active users' do
      active_user = create(:user, tenant: tenant, status: 'active')
      inactive_user = create(:user, tenant: tenant, status: 'inactive')

      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end
  end

  describe '#has_role?' do
    let(:tenant) { create(:tenant) }
    let(:admin_role) { create(:role, name: 'admin', tenant: tenant) }
    let(:user) { create(:user, tenant: tenant) }

    it 'returns true when user has the role' do
      user.roles << admin_role
      expect(user.has_role?('admin')).to be true
    end

    it 'returns false when user does not have the role' do
      expect(user.has_role?('admin')).to be false
    end
  end

  describe '#has_permission?' do
    let(:tenant) { create(:tenant) }
    let(:role) { create(:role, name: 'editor', tenant: tenant, permissions: { 'pipelines' => ['read', 'write'] }) }
    let(:user) { create(:user, tenant: tenant, roles: [role]) }

    it 'returns true when user has the permission' do
      expect(user.has_permission?('pipelines', 'read')).to be true
      expect(user.has_permission?('pipelines', 'write')).to be true
    end

    it 'returns false when user does not have the permission' do
      expect(user.has_permission?('pipelines', 'delete')).to be false
      expect(user.has_permission?('users', 'write')).to be false
    end
  end

  describe '#full_name' do
    it 'returns full name when present' do
      user = build(:user, name: 'John Doe')
      expect(user.full_name).to eq('John Doe')
    end

    it 'returns email when name is blank' do
      user = build(:user, name: nil, email: 'john@example.com')
      expect(user.full_name).to eq('john@example.com')
    end
  end

  describe '#admin?' do
    let(:tenant) { create(:tenant) }
    let(:admin_role) { create(:role, name: 'admin', tenant: tenant) }
    let(:user_role) { create(:role, name: 'user', tenant: tenant) }

    it 'returns true for admin users' do
      admin = create(:user, tenant: tenant, roles: [admin_role])
      expect(admin.admin?).to be true
    end

    it 'returns false for non-admin users' do
      user = create(:user, tenant: tenant, roles: [user_role])
      expect(user.admin?).to be false
    end
  end
end