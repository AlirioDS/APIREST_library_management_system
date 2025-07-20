require 'rails_helper'

RSpec.describe Api::V1::BorrowingsController, type: :controller do
  describe 'GET #index' do
    let(:member) { create(:user, :member) }
    let(:librarian) { create(:user, :librarian) }
    let!(:member_borrowing) { create(:borrowing, user: member) }
    let!(:other_borrowing) { create(:borrowing) }

    context 'when user is a member' do
      before { login_user(member) }

      it 'returns only their own borrowings' do
        get :index

        expect(response).to have_http_status(:ok)
        borrowing_ids = json_response['borrowings'].map { |b| b['id'] }
        expect(borrowing_ids).to include(member_borrowing.id)
        expect(borrowing_ids).not_to include(other_borrowing.id)
      end
    end

    context 'when user is a librarian' do
      before { login_user(librarian) }

      it 'returns all borrowings' do
        get :index

        expect(response).to have_http_status(:ok)
        borrowing_ids = json_response['borrowings'].map { |b| b['id'] }
        expect(borrowing_ids).to include(member_borrowing.id, other_borrowing.id)
      end

      it 'filters by status when provided' do
        overdue_borrowing = create(:borrowing, :overdue)
        
        get :index, params: { status: 'overdue' }

        expect(response).to have_http_status(:ok)
        statuses = json_response['borrowings'].map { |b| b['status'] }
        expect(statuses).to all(eq('overdue'))
      end

      it 'filters by user_id when provided' do
        get :index, params: { user_id: member.id }

        expect(response).to have_http_status(:ok)
        user_ids = json_response['borrowings'].map { |b| b['user']['id'] }
        expect(user_ids).to all(eq(member.id))
      end
    end

    context 'when not authenticated' do
      it 'requires authentication' do
        get :index
        expect_unauthorized_response
      end
    end

    context 'pagination' do
      before do
        login_user(librarian)
        create_list(:borrowing, 25)
      end

      it 'paginates results' do
        get :index, params: { page: 1, per_page: 10 }

        expect(response).to have_http_status(:ok)
        expect(json_response['borrowings'].length).to eq(10)
        expect(json_response['pagination']['current_page']).to eq(1)
        expect(json_response['pagination']['per_page']).to eq(10)
      end
    end
  end

  describe 'GET #show' do
    let(:member) { create(:user, :member) }
    let(:librarian) { create(:user, :librarian) }
    let(:borrowing) { create(:borrowing, user: member) }

    context 'when user owns the borrowing' do
      before { login_user(member) }

      it 'returns borrowing details' do
        get :show, params: { id: borrowing.id }

        expect(response).to have_http_status(:ok)
        expect(json_response['borrowing']['id']).to eq(borrowing.id)
        expect(json_response['borrowing']['user']['id']).to eq(member.id)
      end
    end

    context 'when user is a librarian' do
      before { login_user(librarian) }

      it 'returns borrowing details' do
        get :show, params: { id: borrowing.id }

        expect(response).to have_http_status(:ok)
        expect(json_response['borrowing']['id']).to eq(borrowing.id)
      end
    end

    context 'when user does not own the borrowing' do
      let(:other_member) { create(:user, :member) }
      before { login_user(other_member) }

      it 'denies access' do
        get :show, params: { id: borrowing.id }
        expect_forbidden_response
      end
    end

    context 'when borrowing does not exist' do
      before { login_user(member) }

      it 'returns not found' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Borrowing record not found')
      end
    end
  end

  describe 'POST #borrow_book' do
    let(:member) { create(:user, :member) }
    let(:librarian) { create(:user, :librarian) }
    let(:book) { create(:book, :available, available_copies: 3) }

    context 'when user is a member' do
      before { login_user(member) }

      it 'successfully borrows an available book' do
        expect {
          post :borrow_book, params: { book_id: book.id }
        }.to change(Borrowing, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['message']).to eq('Book borrowed successfully')
        
        borrowing_data = json_response['borrowing']
        expect(borrowing_data['user']['id']).to eq(member.id)
        expect(borrowing_data['book']['id']).to eq(book.id)
        expect(borrowing_data['status']).to eq('borrowed')
        expect(borrowing_data['due_at']).to be_present
      end

      it 'decrements available copies' do
        expect {
          post :borrow_book, params: { book_id: book.id }
        }.to change { book.reload.available_copies }.from(3).to(2)
      end

      it 'prevents borrowing same book twice' do
        create(:borrowing, user: member, book: book)

        post :borrow_book, params: { book_id: book.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('You already have this book borrowed')
      end

      it 'prevents borrowing unavailable book' do
        unavailable_book = create(:book, :checked_out)

        post :borrow_book, params: { book_id: unavailable_book.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Book is not available for borrowing')
      end

      it 'prevents borrowing book with no available copies' do
        book.update!(available_copies: 0)

        post :borrow_book, params: { book_id: book.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Book is not available for borrowing')
      end
    end

    context 'when user is a librarian' do
      before { login_user(librarian) }

      it 'denies access to librarians' do
        post :borrow_book, params: { book_id: book.id }
        expect_forbidden_response
      end
    end

    context 'when book does not exist' do
      before { login_user(member) }

      it 'returns not found' do
        post :borrow_book, params: { book_id: 999999 }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Book not found')
      end
    end

    context 'when not authenticated' do
      it 'requires authentication' do
        post :borrow_book, params: { book_id: book.id }
        expect_unauthorized_response
      end
    end
  end

  describe 'PATCH #return_book' do
    let(:member) { create(:user, :member) }
    let(:librarian) { create(:user, :librarian) }
    let!(:borrowing) { create(:borrowing, user: member) }

    context 'when user is a librarian' do
      before { login_user(librarian) }

      it 'successfully returns the book' do
        patch :return_book, params: { id: borrowing.id }

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Book returned successfully')
        
        borrowing_data = json_response['borrowing']
        expect(borrowing_data['status']).to eq('returned')
        expect(borrowing_data['returned_at']).to be_present
        
        expect(borrowing.reload.status).to eq('returned')
        expect(borrowing.returned_at).to be_present
      end

      it 'increments available copies' do
        book = borrowing.book
        initial_copies = book.available_copies

        patch :return_book, params: { id: borrowing.id }

        expect(book.reload.available_copies).to eq(initial_copies + 1)
      end

      it 'prevents returning already returned book' do
        borrowing.update!(returned_at: Time.current, status: 'returned')

        patch :return_book, params: { id: borrowing.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Book has already been returned')
      end
    end

    context 'when user is a member' do
      before { login_user(member) }

      it 'denies access to members' do
        patch :return_book, params: { id: borrowing.id }
        expect_forbidden_response
      end
    end

    context 'when borrowing does not exist' do
      before { login_user(librarian) }

      it 'returns not found' do
        patch :return_book, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Borrowing record not found')
      end
    end

    context 'when not authenticated' do
      it 'requires authentication' do
        patch :return_book, params: { id: borrowing.id }
        expect_unauthorized_response
      end
    end
  end

  describe 'GET #user_borrowings' do
    let(:librarian) { create(:user, :librarian) }
    let(:member) { create(:user, :member) }
    let!(:user_borrowings) { create_list(:borrowing, 3, user: member) }

    context 'when user is a librarian' do
      before { login_user(librarian) }

      it 'returns borrowings for specified user' do
        get :user_borrowings, params: { user_id: member.id }

        expect(response).to have_http_status(:ok)
        expect(json_response['user']['id']).to eq(member.id)
        expect(json_response['borrowings'].length).to eq(3)
        
        borrowing_user_ids = json_response['borrowings'].map { |b| b['user']['id'] }.uniq
        expect(borrowing_user_ids).to eq([member.id])
      end
    end

    context 'when user is a member' do
      before { login_user(member) }

      it 'denies access' do
        get :user_borrowings, params: { user_id: member.id }
        expect_forbidden_response
      end
    end
  end

  describe 'GET #book_borrowings' do
    let(:librarian) { create(:user, :librarian) }
    let(:book) { create(:book) }
    let!(:book_borrowings) { create_list(:borrowing, 3, book: book) }

    context 'when user is a librarian' do
      before { login_user(librarian) }

      it 'returns borrowings for specified book' do
        get :book_borrowings, params: { book_id: book.id }

        expect(response).to have_http_status(:ok)
        expect(json_response['book']['id']).to eq(book.id)
        expect(json_response['borrowings'].length).to eq(3)
        
        borrowing_book_ids = json_response['borrowings'].map { |b| b['book']['id'] }.uniq
        expect(borrowing_book_ids).to eq([book.id])
      end
    end

    context 'when user is a member' do
      let(:member) { create(:user, :member) }
      before { login_user(member) }

      it 'denies access' do
        get :book_borrowings, params: { book_id: book.id }
        expect_forbidden_response
      end
    end
  end

  describe 'response structure' do
    let(:member) { create(:user, :member) }
    let(:borrowing) { create(:borrowing, user: member) }

    before { login_user(member) }

    it 'includes correct borrowing data structure' do
      get :show, params: { id: borrowing.id }

      borrowing_data = json_response['borrowing']
      expected_fields = %w[
        id user book borrowed_at due_at returned_at status 
        overdue days_until_due days_overdue borrowing_period_days
        created_at updated_at
      ]
      expect(borrowing_data.keys).to match_array(expected_fields)
    end

    it 'includes nested user and book information' do
      get :show, params: { id: borrowing.id }

      borrowing_data = json_response['borrowing']
      expect(borrowing_data['user']).to include('id', 'name', 'email')
      expect(borrowing_data['book']).to include('id', 'title', 'author')
    end

    it 'includes calculated fields' do
      get :show, params: { id: borrowing.id }

      borrowing_data = json_response['borrowing']
      expect(borrowing_data['overdue']).to be_in([true, false])
      expect(borrowing_data['days_until_due']).to be_a(Integer)
      expect(borrowing_data['days_overdue']).to be_a(Integer)
    end
  end
end 
