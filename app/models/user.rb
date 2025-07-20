class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :borrowings, dependent: :destroy
  has_many :borrowed_books, through: :borrowings, source: :book

  # Roles enumeration for Library System
  enum :role, { member: "member", librarian: "librarian" }, default: "member"

  # Scopes
  scope :member, -> { where(role: "member") }
  scope :librarian, -> { where(role: "librarian") }

  # Validations
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: :password_digest_changed?

  # Normalization
  normalizes :email_address, with: ->(email) { email.strip.downcase }

  # Generate JWT token
  def generate_jwt_token
    payload = {
      user_id: id,
      email: email_address,
      role: role,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, jwt_secret_key, "HS256")
  end

  # Generate refresh token (longer lived)
  def generate_refresh_token
    payload = {
      user_id: id,
      type: "refresh",
      exp: 7.days.from_now.to_i
    }
    JWT.encode(payload, jwt_secret_key, "HS256")
  end

  # Decode JWT token
  def self.decode_jwt_token(token)
    decoded = JWT.decode(token, jwt_secret_key, true, { algorithm: "HS256" })
    decoded[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  # Role checks for Library System
  def librarian?
    role == "librarian"
  end

  def member?
    role == "member"
  end

  # Borrowing helper methods
  def active_borrowings
    borrowings.active
  end

  def can_borrow_book?(book)
    return false unless member?
    return false unless book.available?
    return false if has_borrowed_book?(book)
    true
  end

  def has_borrowed_book?(book)
    borrowings.active.exists?(book: book)
  end

  def overdue_borrowings
    borrowings.overdue
  end

  def borrowings_count
    borrowings.active.count
  end

  private

  def self.jwt_secret_key
    Rails.application.secret_key_base
  end

  def jwt_secret_key
    self.class.jwt_secret_key
  end
end
