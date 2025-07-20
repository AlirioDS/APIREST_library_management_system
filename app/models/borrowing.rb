class Borrowing < ApplicationRecord
  belongs_to :user
  belongs_to :book

  # Enums
  enum :status, { borrowed: "borrowed", returned: "returned", overdue: "overdue" }

  # Validations
  validates :borrowed_at, presence: true
  validates :due_at, presence: true
  validates :user_id, uniqueness: {
    scope: [ :book_id ],
    conditions: -> { where(returned_at: nil) },
    message: "already has this book borrowed"
  }
  validate :due_at_after_borrowed_at
  validate :book_available_when_borrowing, on: :create
  validate :returned_at_after_borrowed_at, if: :returned_at?

  # Callbacks
  before_validation :set_default_dates, on: :create
  after_create :decrement_book_availability
  after_update :increment_book_availability, if: :saved_change_to_returned_at?

  # Scopes
  scope :active, -> { where(returned_at: nil) }
  scope :returned, -> { where.not(returned_at: nil) }
  scope :overdue, -> { where("due_at < ? AND returned_at IS NULL", Time.current) }
  scope :due_soon, ->(days = 3) { where("due_at <= ? AND due_at >= ? AND returned_at IS NULL", days.days.from_now, Time.current) }

  # Instance methods
  def active?
    returned_at.nil?
  end

  def overdue?
    active? && due_at < Time.current
  end

  def days_overdue
    return 0 unless overdue?
    (Time.current.to_date - due_at.to_date).to_i
  end

  def days_until_due
    return 0 if returned?
    (due_at.to_date - Time.current.to_date).to_i
  end

  def return_book!
    update!(returned_at: Time.current, status: "returned")
  end

  def borrowing_period_days
    return nil if borrowed_at.nil? || due_at.nil?
    (due_at.to_date - borrowed_at.to_date).to_i
  end

  # Class methods
  def self.update_overdue_status
    overdue.update_all(status: "overdue")
  end

  private

  def set_default_dates
    self.borrowed_at ||= Time.current
    self.due_at ||= 2.weeks.from_now(borrowed_at)
  end

  def due_at_after_borrowed_at
    return unless borrowed_at && due_at

    if due_at <= borrowed_at
      errors.add(:due_at, "must be after borrowed date")
    end
  end

  def returned_at_after_borrowed_at
    return unless borrowed_at && returned_at

    if returned_at < borrowed_at
      errors.add(:returned_at, "cannot be before borrowed date")
    end
  end

  def book_available_when_borrowing
    return unless book

    unless book.available?
      errors.add(:book, "is not available for borrowing")
    end

    if book.available_copies <= 0
      errors.add(:book, "has no available copies")
    end
  end

  def decrement_book_availability
    book.decrement!(:available_copies)
    book.update!(status: "checked_out") if book.available_copies == 0
  end

  def increment_book_availability
    return unless returned_at && returned_at_previously_was.nil?

    book.increment!(:available_copies)
    book.update!(status: "available") if book.available_copies > 0
  end
end
