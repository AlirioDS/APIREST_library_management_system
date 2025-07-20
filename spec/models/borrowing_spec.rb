require 'rails_helper'

RSpec.describe Borrowing, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:book) }
  end

  describe 'validations' do
    it 'validates presence of borrowed_at after set_default_dates callback' do
      borrowing = build(:borrowing, borrowed_at: nil)
      borrowing.valid?
      expect(borrowing.borrowed_at).to be_present
    end

    it 'validates presence of due_at after set_default_dates callback' do
      borrowing = build(:borrowing, due_at: nil)
      borrowing.valid?
      expect(borrowing.due_at).to be_present
    end

    describe 'uniqueness validation' do
      let(:user) { create(:user) }
      let(:book) { create(:book) }

      it 'prevents user from borrowing same book multiple times when active' do
        create(:borrowing, user: user, book: book)
        duplicate_borrowing = build(:borrowing, user: user, book: book)
        
        expect(duplicate_borrowing).not_to be_valid
        expect(duplicate_borrowing.errors[:user_id]).to include('already has this book borrowed')
      end

      it 'allows user to borrow same book again after returning' do
        create(:borrowing, :returned, user: user, book: book)
        new_borrowing = build(:borrowing, user: user, book: book)
        
        expect(new_borrowing).to be_valid
      end
    end

    describe 'custom validations' do
      let(:borrowing) { build(:borrowing) }

      describe 'due_at_after_borrowed_at' do
        it 'is valid when due_at is after borrowed_at' do
          borrowing.borrowed_at = 1.day.ago
          borrowing.due_at = 1.week.from_now
          expect(borrowing).to be_valid
        end

        it 'is invalid when due_at is before borrowed_at' do
          borrowing.borrowed_at = 1.day.ago
          borrowing.due_at = 2.days.ago
          expect(borrowing).not_to be_valid
          expect(borrowing.errors[:due_at]).to include('must be after borrowed date')
        end
      end

      describe 'book_available_when_borrowing' do
        it 'is valid when book is available' do
          available_book = create(:book, :available)
          borrowing.book = available_book
          expect(borrowing).to be_valid
        end

        it 'is invalid when book is not available' do
          unavailable_book = create(:book, :checked_out)
          borrowing.book = unavailable_book
          expect(borrowing).not_to be_valid
          expect(borrowing.errors[:book]).to include('is not available for borrowing')
        end

        it 'is invalid when book has no available copies' do
          book = create(:book, available_copies: 0)
          borrowing.book = book
          expect(borrowing).not_to be_valid
          expect(borrowing.errors[:book]).to include('has no available copies')
        end
      end

      describe 'returned_at_after_borrowed_at' do
        it 'is valid when returned_at is after borrowed_at' do
          borrowing.borrowed_at = 1.week.ago
          borrowing.returned_at = 1.day.ago
          expect(borrowing).to be_valid
        end

        it 'is invalid when returned_at is before borrowed_at' do
          borrowing.borrowed_at = 1.day.ago
          borrowing.returned_at = 2.days.ago
          expect(borrowing).not_to be_valid
          expect(borrowing.errors[:returned_at]).to include('cannot be before borrowed date')
        end
      end
    end
  end

  describe 'enums' do
    it 'defines status enum with string values' do
      expect(Borrowing.statuses).to eq({
        'borrowed' => 'borrowed',
        'returned' => 'returned',
        'overdue' => 'overdue'
      })
    end
  end

  describe 'scopes' do
    let!(:active_borrowing) { create(:borrowing, :borrowed) }
    let!(:returned_borrowing) { create(:borrowing, :returned) }
    let!(:overdue_borrowing) { create(:borrowing, :overdue) }
    let!(:due_soon_borrowing) { create(:borrowing, :due_soon) }

    describe '.active' do
      it 'returns borrowings without returned_at' do
        expect(Borrowing.active).to include(active_borrowing, overdue_borrowing)
        expect(Borrowing.active).not_to include(returned_borrowing)
      end
    end

    describe '.returned' do
      it 'returns borrowings with returned_at' do
        expect(Borrowing.returned).to include(returned_borrowing)
        expect(Borrowing.returned).not_to include(active_borrowing, overdue_borrowing)
      end
    end

    describe '.overdue' do
      it 'returns borrowings past due date and not returned' do
        expect(Borrowing.overdue).to include(overdue_borrowing)
        expect(Borrowing.overdue).not_to include(active_borrowing, returned_borrowing)
      end
    end

    describe '.due_soon' do
      it 'returns borrowings due within specified days' do
        # Create a specific borrowing that's due within 2 days
        user = create(:user)
        book = create(:book)
        due_soon_borrowing = create(:borrowing, 
          user: user, 
          book: book,
          borrowed_at: 12.days.ago,
          due_at: 2.days.from_now,
          status: 'borrowed'
        )
        
        expect(Borrowing.due_soon(3)).to include(due_soon_borrowing)
        expect(Borrowing.due_soon(3)).not_to include(overdue_borrowing, returned_borrowing)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation :set_default_dates' do
      it 'sets borrowed_at to current time if not provided' do
        borrowing = build(:borrowing, borrowed_at: nil)
        borrowing.valid?
        expect(borrowing.borrowed_at).to be_within(1.second).of(Time.current)
      end

      it 'sets due_at to 2 weeks from borrowed_at if not provided' do
        borrowed_at = 1.day.ago
        borrowing = build(:borrowing, borrowed_at: borrowed_at, due_at: nil)
        borrowing.valid?
        expect(borrowing.due_at).to be_within(1.second).of(2.weeks.from_now(borrowed_at))
      end

      it 'does not override provided dates' do
        borrowed_at = 1.week.ago
        due_at = 1.week.from_now
        borrowing = build(:borrowing, borrowed_at: borrowed_at, due_at: due_at)
        borrowing.valid?
        expect(borrowing.borrowed_at).to be_within(1.second).of(borrowed_at)
        expect(borrowing.due_at).to be_within(1.second).of(due_at)
      end
    end

    describe 'after_create :decrement_book_availability' do
      it 'decrements book available_copies after creation' do
        book = create(:book, available_copies: 5)
        expect {
          create(:borrowing, book: book)
        }.to change { book.reload.available_copies }.from(5).to(4)
      end

      it 'sets book status to checked_out when no copies available' do
        book = create(:book, available_copies: 1, status: 'available')
        create(:borrowing, book: book)
        
        expect(book.reload.status).to eq('checked_out')
        expect(book.available_copies).to eq(0)
      end
    end

    describe 'after_update :increment_book_availability' do
      it 'increments book available_copies when returned' do
        book = create(:book, total_copies: 5, available_copies: 4) # Start with 4 since creating borrowing decrements to 3
        borrowing = create(:borrowing, book: book)
        book.reload # Refresh to see decremented value (should be 3)
        
        expect {
          borrowing.update!(returned_at: Time.current, status: 'returned')
        }.to change { book.reload.available_copies }.by(1)
      end

      it 'sets book status to available when copies become available' do
        book = create(:book, available_copies: 1, status: 'available') # Will become 0 after borrowing
        borrowing = create(:borrowing, book: book)
        
        # Verify book is checked out after borrowing
        expect(book.reload.status).to eq('checked_out')
        expect(book.available_copies).to eq(0)
        
        borrowing.update!(returned_at: Time.current, status: 'returned')
        
        expect(book.reload.status).to eq('available')
        expect(book.available_copies).to eq(1)
      end
    end
  end

  describe 'instance methods' do
    let(:borrowing) { create(:borrowing) }

    describe '#active?' do
      it 'returns true when returned_at is nil' do
        borrowing.returned_at = nil
        expect(borrowing.active?).to be_truthy
      end

      it 'returns false when returned_at is present' do
        borrowing.returned_at = Time.current
        expect(borrowing.active?).to be_falsey
      end
    end

    describe '#overdue?' do
      it 'returns true when active and past due date' do
        borrowing.due_at = 1.day.ago
        borrowing.returned_at = nil
        expect(borrowing.overdue?).to be_truthy
      end

      it 'returns false when not active' do
        borrowing.due_at = 1.day.ago
        borrowing.returned_at = Time.current
        expect(borrowing.overdue?).to be_falsey
      end

      it 'returns false when not past due date' do
        borrowing.due_at = 1.day.from_now
        borrowing.returned_at = nil
        expect(borrowing.overdue?).to be_falsey
      end
    end

    describe '#days_overdue' do
      it 'returns number of days overdue when overdue' do
        borrowing.due_at = 5.days.ago.to_date
        borrowing.returned_at = nil
        expect(borrowing.days_overdue).to eq(5)
      end

      it 'returns 0 when not overdue' do
        borrowing.due_at = 1.day.from_now
        expect(borrowing.days_overdue).to eq(0)
      end

      it 'returns 0 when returned' do
        borrowing.due_at = 5.days.ago
        borrowing.returned_at = Time.current
        expect(borrowing.days_overdue).to eq(0)
      end
    end

    describe '#days_until_due' do
      it 'returns number of days until due when active' do
        borrowing.due_at = 3.days.from_now.to_date
        borrowing.returned_at = nil
        expect(borrowing.days_until_due).to eq(3)
      end

      it 'returns 0 when returned' do
        borrowing.due_at = 3.days.from_now
        borrowing.status = 'returned'
        borrowing.returned_at = Time.current
        expect(borrowing.days_until_due).to eq(0)
      end
    end

    describe '#return_book!' do
      it 'sets returned_at and status to returned' do
        expect {
          borrowing.return_book!
        }.to change { borrowing.returned_at }.from(nil).to(be_within(1.second).of(Time.current))
        .and change { borrowing.status }.to('returned')
      end
    end

    describe '#borrowing_period_days' do
      it 'returns number of days between borrowed_at and due_at' do
        borrowing.borrowed_at = 2.weeks.ago.to_date
        borrowing.due_at = Date.current
        expect(borrowing.borrowing_period_days).to eq(14)
      end

      it 'returns nil when dates are missing' do
        borrowing.borrowed_at = nil
        expect(borrowing.borrowing_period_days).to be_nil
      end
    end
  end

  describe 'class methods' do
    describe '.update_overdue_status' do
      it 'updates status to overdue for overdue borrowings' do
        overdue_borrowing = create(:borrowing, 
          borrowed_at: 3.weeks.ago, 
          due_at: 1.week.ago, 
          status: 'borrowed'
        )
        current_borrowing = create(:borrowing, 
          borrowed_at: 1.week.ago, 
          due_at: 1.week.from_now, 
          status: 'borrowed'
        )

        Borrowing.update_overdue_status

        expect(overdue_borrowing.reload.status).to eq('overdue')
        expect(current_borrowing.reload.status).to eq('borrowed')
      end
    end
  end
end 
