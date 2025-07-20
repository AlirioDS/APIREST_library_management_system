require 'rails_helper'

RSpec.describe Book, type: :model do
  subject { build(:book) }
  
  describe 'associations' do
    it { should have_many(:borrowings).dependent(:destroy) }
    it { should have_many(:borrowers).through(:borrowings).source(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(1).is_at_most(255) }
    it { should validate_presence_of(:author) }
    it { should validate_length_of(:author).is_at_least(1).is_at_most(255) }
    it { should validate_uniqueness_of(:isbn).case_insensitive.allow_blank }
    it { should validate_numericality_of(:total_copies).is_greater_than(0) }
    it { should validate_numericality_of(:available_copies).is_greater_than_or_equal_to(0) }

    describe 'publication_year validation' do
      it 'validates publication year is reasonable' do
        book = build(:book, publication_year: 500)
        expect(book).not_to be_valid
        expect(book.errors[:publication_year]).to be_present
      end

      it 'allows future publication year within reason' do
        book = build(:book, publication_year: Date.current.year + 1)
        expect(book).to be_valid
      end
    end

    describe 'available_copies validation' do
      it 'validates available copies does not exceed total copies' do
        book = build(:book, total_copies: 5, available_copies: 10)
        expect(book).not_to be_valid
        expect(book.errors[:available_copies]).to be_present
      end
    end
  end

  describe 'enums' do
    it 'defines status enum with string values' do
      expect(Book.statuses).to eq({
        'available' => 'available',
        'checked_out' => 'checked_out', 
        'maintenance' => 'maintenance',
        'lost' => 'lost'
      })
    end
  end

  describe 'scopes' do
    let!(:available_book) { create(:book, :available) }
    let!(:checked_out_book) { create(:book, :checked_out) }
    let!(:fiction_book) { create(:book, genre: 'Fiction') }
    let!(:science_book) { create(:book, genre: 'Science') }

    describe '.available' do
      it 'returns only available books' do
        expect(Book.available).to include(available_book)
        expect(Book.available).not_to include(checked_out_book)
      end
    end

    describe '.by_genre' do
      it 'filters books by genre' do
        expect(Book.by_genre('Fiction')).to include(fiction_book)
        expect(Book.by_genre('Fiction')).not_to include(science_book)
      end

      it 'returns all books when genre is blank' do
        expect(Book.by_genre('')).to include(fiction_book, science_book)
      end
    end

    describe '.by_author' do
      let!(:tolkien_book) { create(:book, author: 'J.R.R. Tolkien') }
      let!(:martin_book) { create(:book, author: 'George R.R. Martin') }

      it 'filters books by author with partial match' do
        expect(Book.by_author('Tolkien')).to include(tolkien_book)
        expect(Book.by_author('Tolkien')).not_to include(martin_book)
      end

      it 'is case insensitive' do
        expect(Book.by_author('tolkien')).to include(tolkien_book)
      end
    end

    describe '.by_title' do
      let!(:gatsby_book) { create(:book, title: 'The Great Gatsby') }
      let!(:mockingbird_book) { create(:book, title: 'To Kill a Mockingbird') }

      it 'filters books by title with partial match' do
        expect(Book.by_title('Gatsby')).to include(gatsby_book)
        expect(Book.by_title('Gatsby')).not_to include(mockingbird_book)
      end

      it 'is case insensitive' do
        expect(Book.by_title('gatsby')).to include(gatsby_book)
      end
    end
  end

  describe '.search' do
    let!(:book1) { create(:book, title: 'Clean Code', author: 'Robert Martin', genre: 'Programming') }
    let!(:book2) { create(:book, title: 'The Pragmatic Programmer', author: 'Dave Thomas', genre: 'Programming') }
    let!(:book3) { create(:book, title: 'Design Patterns', author: 'Gang of Four', publisher: 'Addison-Wesley') }

    it 'searches across title, author, genre, and publisher' do
      expect(Book.search('Programming')).to include(book1, book2)
      expect(Book.search('Programming')).not_to include(book3)

      expect(Book.search('Robert')).to include(book1)
      expect(Book.search('Robert')).not_to include(book2, book3)

      expect(Book.search('Addison')).to include(book3)
      expect(Book.search('Addison')).not_to include(book1, book2)
    end

    it 'is case insensitive' do
      expect(Book.search('programming')).to include(book1, book2)
    end

    it 'returns all books when query is blank' do
      expect(Book.search('')).to include(book1, book2, book3)
      expect(Book.search(nil)).to include(book1, book2, book3)
    end
  end

  describe 'instance methods' do
    let(:book) { create(:book, total_copies: 5, available_copies: 3, status: 'available') }

    describe '#available?' do
      it 'returns true when status is available and has available copies' do
        expect(book.available?).to be_truthy
      end

      it 'returns false when status is not available' do
        book.update(status: 'maintenance')
        expect(book.available?).to be_falsey
      end

      it 'returns false when no available copies' do
        book.update(available_copies: 0)
        expect(book.available?).to be_falsey
      end
    end

    describe '#can_be_checked_out?' do
      it 'returns true when book is available and has copies' do
        expect(book.can_be_checked_out?).to be_truthy
      end

      it 'returns false when book is not available' do
        book.update(status: 'maintenance')
        expect(book.can_be_checked_out?).to be_falsey
      end
    end

    describe '#full_title' do
      it 'returns title with author' do
        book = create(:book, title: 'Clean Code', author: 'Robert Martin')
        expect(book.full_title).to eq('Clean Code by Robert Martin')
      end
    end

    describe '#published_info' do
      it 'returns publisher and year when both present' do
        book = create(:book, publisher: 'Prentice Hall', publication_year: 2008)
        expect(book.published_info).to eq('Prentice Hall (2008)')
      end

      it 'returns only publisher when year is blank' do
        book = create(:book, publisher: 'Prentice Hall', publication_year: nil)
        expect(book.published_info).to eq('Prentice Hall')
      end

      it 'returns only year when publisher is blank' do
        book = create(:book, publisher: nil, publication_year: 2008)
        expect(book.published_info).to eq('2008')
      end
    end

    describe '#active_borrowings' do
      it 'returns only active borrowings for the book' do
        active_borrowing = create(:borrowing, book: book)
        returned_borrowing = create(:borrowing, :returned, book: book)

        expect(book.active_borrowings).to include(active_borrowing)
        expect(book.active_borrowings).not_to include(returned_borrowing)
      end
    end

    describe '#current_borrowers' do
      it 'returns users who currently have the book borrowed' do
        user = create(:user)
        create(:borrowing, book: book, user: user)
        returned_user = create(:user)
        create(:borrowing, :returned, book: book, user: returned_user)

        expect(book.current_borrowers).to include(user)
        expect(book.current_borrowers).not_to include(returned_user)
      end
    end

    describe '#borrowed_by?' do
      let(:user) { create(:user) }

      it 'returns true when user has active borrowing' do
        create(:borrowing, book: book, user: user)
        expect(book.borrowed_by?(user)).to be_truthy
      end

      it 'returns false when user has no active borrowing' do
        expect(book.borrowed_by?(user)).to be_falsey
      end
    end

    describe '#times_borrowed' do
      it 'returns total number of times book has been borrowed' do
        book = create(:book, total_copies: 15, available_copies: 15)
        create_list(:borrowing, 3, book: book)
        create_list(:borrowing, 2, :returned, book: book)

        expect(book.times_borrowed).to eq(5)
      end
    end
  end

  describe 'normalization' do
    it 'normalizes title and author by stripping whitespace' do
      book = create(:book, title: '  Clean Code  ', author: '  Robert Martin  ')
      expect(book.title).to eq('Clean Code')
      expect(book.author).to eq('Robert Martin')
    end

    it 'normalizes ISBN by removing dashes and spaces' do
      book = create(:book, isbn: '978-0-13-999999-4')
      expect(book.isbn).to eq('9780139999994'.upcase)
    end
  end
end 
