class Profile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  # Store additional user information
  # Fields: bio, website, location, timezone, preferences (JSONB)
end