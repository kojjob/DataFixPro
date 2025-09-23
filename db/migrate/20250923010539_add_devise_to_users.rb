# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def self.up
    change_table :users do |t|
      ## Database authenticatable - email already exists, just need encrypted_password
      t.string :encrypted_password, null: false, default: "" unless column_exists?(:users, :encrypted_password)

      ## Recoverable
      t.string   :reset_password_token unless column_exists?(:users, :reset_password_token)
      t.datetime :reset_password_sent_at unless column_exists?(:users, :reset_password_sent_at)

      ## Rememberable
      t.datetime :remember_created_at unless column_exists?(:users, :remember_created_at)

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false unless column_exists?(:users, :sign_in_count)
      t.datetime :current_sign_in_at unless column_exists?(:users, :current_sign_in_at)
      t.datetime :last_sign_in_at unless column_exists?(:users, :last_sign_in_at)
      t.string   :current_sign_in_ip unless column_exists?(:users, :current_sign_in_ip)
      t.string   :last_sign_in_ip unless column_exists?(:users, :last_sign_in_ip)

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false unless column_exists?(:users, :failed_attempts)
      t.string   :unlock_token unless column_exists?(:users, :unlock_token)
      t.datetime :locked_at unless column_exists?(:users, :locked_at)
    end

    # Remove password_digest since we're using Devise's encrypted_password
    remove_column :users, :password_digest if column_exists?(:users, :password_digest)

    # Remove our custom password reset fields since Devise handles this
    remove_column :users, :password_reset_token if column_exists?(:users, :password_reset_token) && column_exists?(:users, :reset_password_token)
    remove_column :users, :password_reset_sent_at if column_exists?(:users, :password_reset_sent_at) && column_exists?(:users, :reset_password_sent_at)

    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
    add_index :users, :unlock_token,         unique: true unless index_exists?(:users, :unlock_token)
  end

  def self.down
    # By default, we don't want to make any assumption about how to roll back a migration when your
    # model already existed. Please edit below which fields you would like to remove in this migration.
    raise ActiveRecord::IrreversibleMigration
  end
end
