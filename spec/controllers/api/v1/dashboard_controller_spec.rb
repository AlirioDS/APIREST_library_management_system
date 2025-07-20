require 'rails_helper'

RSpec.describe Api::V1::DashboardController, type: :controller do
  describe 'GET #librarian' do
    let(:librarian) { create(:user, :librarian) }
    let(:member) { create(:user, :member) }

    before do
      # Setup test data
      create_list(:book, 10)
      create_list(:borrowing, 5)
      create_list(:borrowing, 2, :overdue)
      create(:borrowing, :due_today)
    end

    context 'when user is a librarian' do
      before { login_user(librarian) }

      it 'returns librarian dashboard data' do
        get :librarian

        expect(response).to have_http_status(:ok)
        dashboard = json_response['dashboard']

        expect(dashboard).to have_key('overview')
        expect(dashboard).to have_key('books_due_today')
        expect(dashboard).to have_key('overdue_members')
        expect(dashboard).to have_key('recent_borrowings')
        expect(dashboard).to have_key('popular_books')
      end

      it 'includes correct overview statistics' do
        get :librarian

        overview = json_response['dashboard']['overview']
        expect(overview['total_books']).to eq(Book.count)
        expect(overview['borrowed_books']).to eq(Borrowing.active.count)
        expect(overview['overdue_books']).to eq(Borrowing.overdue.count)
        expect(overview['total_members']).to eq(User.member.count)
      end

      it 'includes books due today' do
        get :librarian

        books_due_today = json_response['dashboard']['books_due_today']
        expect(books_due_today).to be_an(Array)

        if books_due_today.any?
          book_due = books_due_today.first
          expect(book_due).to include('id', 'user', 'book', 'due_at', 'days_until_due')
        end
      end

      it 'includes overdue members with their books' do
        get :librarian

        overdue_members = json_response['dashboard']['overdue_members']
        expect(overdue_members).to be_an(Array)

        if overdue_members.any?
          overdue_member = overdue_members.first
          expect(overdue_member).to include('user', 'overdue_count', 'total_days_overdue', 'books')
          expect(overdue_member['user']).to include('id', 'name', 'email')
        end
      end

      it 'includes recent borrowings' do
        get :librarian

        recent_borrowings = json_response['dashboard']['recent_borrowings']
        expect(recent_borrowings).to be_an(Array)
        expect(recent_borrowings.length).to be <= 10

        if recent_borrowings.any?
          borrowing = recent_borrowings.first
          expect(borrowing).to include('id', 'user', 'book', 'borrowed_at', 'status')
        end
      end

      it 'includes popular books' do
        get :librarian

        popular_books = json_response['dashboard']['popular_books']
        expect(popular_books).to be_an(Array)
        expect(popular_books.length).to be <= 5

        if popular_books.any?
          book = popular_books.first
          expect(book).to include('id', 'title', 'author', 'times_borrowed')
        end
      end
    end

    context 'when user is a member' do
      before { login_user(member) }

      it 'denies access to librarian dashboard' do
        get :librarian
        expect_forbidden_response
      end
    end

    context 'when not authenticated' do
      it 'requires authentication' do
        get :librarian
        expect_unauthorized_response
      end
    end
  end

  describe 'GET #member' do
    let(:member) { create(:user, :member) }
    let(:librarian) { create(:user, :librarian) }

    before do
      # Setup test data for member
      create_list(:borrowing, 3, user: member)
      create_list(:borrowing, 2, :returned, user: member)
      create(:borrowing, :overdue, user: member)

      # Create some books for recommendations
      create_list(:book, 5, genre: 'Fiction')
      create_list(:book, 3, genre: 'Science')
    end

    context 'when user is a member' do
      before { login_user(member) }

      it 'returns member dashboard data' do
        get :member

        expect(response).to have_http_status(:ok)
        dashboard = json_response['dashboard']

        expect(dashboard).to have_key('overview')
        expect(dashboard).to have_key('active_borrowings')
        expect(dashboard).to have_key('borrowing_history')
        expect(dashboard).to have_key('recommendations')
      end

      it 'includes correct member overview statistics' do
        get :member

        overview = json_response['dashboard']['overview']
        expect(overview['total_books_borrowed']).to eq(member.borrowings.count)
        expect(overview['currently_borrowed']).to eq(member.borrowings.active.count)
        expect(overview['books_returned']).to eq(member.borrowings.returned.count)
        expect(overview['overdue_books']).to eq(member.borrowings.overdue.count)
      end

      it 'includes active borrowings with book details' do
        get :member

        active_borrowings = json_response['dashboard']['active_borrowings']
        expect(active_borrowings).to be_an(Array)

        if active_borrowings.any?
          borrowing = active_borrowings.first
          expect(borrowing).to include('id', 'book', 'borrowed_at', 'due_at', 'status')
          expect(borrowing['book']).to include('id', 'title', 'author', 'genre')
        end
      end

      it 'includes borrowing history' do
        get :member

        borrowing_history = json_response['dashboard']['borrowing_history']
        expect(borrowing_history).to be_an(Array)
        expect(borrowing_history.length).to be <= 10

        if borrowing_history.any?
          borrowing = borrowing_history.first
          expect(borrowing).to include('id', 'book', 'returned_at')
        end
      end

      it 'includes book recommendations' do
        get :member

        recommendations = json_response['dashboard']['recommendations']
        expect(recommendations).to be_an(Array)
        expect(recommendations.length).to be <= 5

        if recommendations.any?
          book = recommendations.first
          expect(book).to include('id', 'title', 'author', 'genre', 'available_copies')
        end
      end

      it 'shows borrowing limit status' do
        get :member

        overview = json_response['dashboard']['overview']
        expect(overview).to have_key('borrowing_limit_reached')
        expect(overview['borrowing_limit_reached']).to be_in([ true, false ])
      end
    end

    context 'when user is a librarian' do
      before { login_user(librarian) }

      it 'denies access to member dashboard' do
        get :member
        expect_forbidden_response
      end
    end

    context 'when not authenticated' do
      it 'requires authentication' do
        get :member
        expect_unauthorized_response
      end
    end
  end

  describe 'dashboard data accuracy' do
    let(:librarian) { create(:user, :librarian) }
    let(:member1) { create(:user, :member) }
    let(:member2) { create(:user, :member) }

    before do
      login_user(librarian)

      # Create specific test scenario
      @book1 = create(:book, :available, total_copies: 5, available_copies: 3)
      @book2 = create(:book, :available, total_copies: 3, available_copies: 1, status: 'available')

      @borrowing1 = create(:borrowing, user: member1, book: @book1, borrowed_at: 1.week.ago)
      @borrowing2 = create(:borrowing, :overdue, user: member2, book: @book2)
      @borrowing3 = create(:borrowing, :due_today, user: member1)
    end

    it 'accurately counts different book statuses' do
      get :librarian

      overview = json_response['dashboard']['overview']
      expect(overview['total_books']).to eq(Book.count)
      expect(overview['available_books']).to eq(Book.where(status: 'available').count)
      expect(overview['borrowed_books']).to eq(Borrowing.active.count)
    end

    it 'accurately identifies overdue situations' do
      get :librarian

      overview = json_response['dashboard']['overview']
      overdue_members = json_response['dashboard']['overdue_members']

      expect(overview['overdue_books']).to eq(Borrowing.overdue.count)
      expect(overdue_members.length).to eq(1) # Only member2 has overdue books

      overdue_member = overdue_members.first
      expect(overdue_member['user']['id']).to eq(member2.id)
      expect(overdue_member['overdue_count']).to eq(1)
    end

    it 'accurately identifies books due today' do
      get :librarian

      books_due_today = json_response['dashboard']['books_due_today']
      overview = json_response['dashboard']['overview']

      expect(overview['books_due_today']).to eq(1)
      expect(books_due_today.length).to eq(1)
      expect(books_due_today.first['id']).to eq(@borrowing3.id)
    end
  end

  describe 'response structure consistency' do
    let(:member) { create(:user, :member) }

    before do
      login_user(member)
      create(:borrowing, user: member)
    end

    it 'includes consistent data structure for member dashboard' do
      get :member

      dashboard = json_response['dashboard']

      # Check overview structure
      overview = dashboard['overview']
      expected_overview_fields = %w[
        total_books_borrowed currently_borrowed books_returned
        overdue_books books_due_soon borrowing_limit_reached
      ]
      expect(overview.keys).to match_array(expected_overview_fields)

      # Check active borrowings structure
      if dashboard['active_borrowings'].any?
        borrowing = dashboard['active_borrowings'].first
        expect(borrowing).to include('id', 'book', 'borrowed_at', 'due_at', 'status', 'can_renew')
        expect(borrowing['book']).to include('id', 'title', 'author', 'genre')
      end
    end
  end

  describe 'error handling' do
    let(:librarian) { create(:user, :librarian) }

    before { login_user(librarian) }

    it 'handles empty data gracefully' do
      # Clear all data
      Borrowing.destroy_all
      Book.destroy_all
      User.member.destroy_all

      get :librarian

      expect(response).to have_http_status(:ok)
      dashboard = json_response['dashboard']

      expect(dashboard['overview']['total_books']).to eq(0)
      expect(dashboard['overview']['borrowed_books']).to eq(0)
      expect(dashboard['books_due_today']).to eq([])
      expect(dashboard['overdue_members']).to eq([])
    end
  end
end
