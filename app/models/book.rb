class Book < ApplicationRecord
  has_many :borrowings, dependent: :destroy
  has_many :borrowers, through: :borrowings, source: :user
  
  # Enums
  enum :status, { available: 'available', checked_out: 'checked_out', maintenance: 'maintenance', lost: 'lost' }
  
  # Validations
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :author, presence: true, length: { minimum: 1, maximum: 255 }
  validates :isbn, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :publication_year, numericality: { 
    greater_than: 1000, 
    less_than_or_equal_to: Date.current.year + 1 
  }, allow_blank: true
  validates :total_copies, numericality: { greater_than: 0 }
  validates :available_copies, numericality: { 
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: :total_copies 
  }
  
  # Normalizations
  normalizes :title, with: ->(title) { title.strip }
  normalizes :author, with: ->(author) { author.strip }
  normalizes :isbn, with: ->(isbn) { isbn&.gsub(/[-\s]/, '')&.upcase }
  
  # Scopes
  scope :available, -> { where(status: 'available') }
  scope :by_genre, ->(genre) { where(genre: genre) if genre.present? }
  scope :by_author, ->(author) { where('author ILIKE ?', "%#{author}%") if author.present? }
  scope :by_title, ->(title) { where('title ILIKE ?', "%#{title}%") if title.present? }
  
  # Methods
  def available?
    status == 'available' && available_copies > 0
  end
  
  def can_be_checked_out?
    available? && available_copies > 0
  end
  
  def full_title
    "#{title} by #{author}"
  end
  
  def published_info
    return publisher if publication_year.blank?
    return publication_year.to_s if publisher.blank?
    "#{publisher} (#{publication_year})"
  end
  
  # Class methods
  def self.search(query)
    return all if query.blank?
    
    where(
      'title ILIKE :query OR author ILIKE :query OR genre ILIKE :query OR publisher ILIKE :query',
      query: "%#{query}%"
    )
  end
  
  # Borrowing helper methods
  def active_borrowings
    borrowings.active
  end
  
  def current_borrowers
    borrowers.joins(:borrowings).where(borrowings: { returned_at: nil })
  end
  
  def borrowed_by?(user)
    borrowings.active.exists?(user: user)
  end
  
  def times_borrowed
    borrowings.count
  end
end 
