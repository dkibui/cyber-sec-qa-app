class User < ApplicationRecord
  has_secure_password
  include Roles
  has_many :sessions, dependent: :destroy

  validates :password, length: { minimum: 8 }, allow_nil: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
