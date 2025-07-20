require 'rails_helper'

RSpec.describe Api::V1::BooksController, type: :controller do
  describe 'GET #index' do
    let!(:book1) { create(:book, title: 'Test Book 1', author: 'Author 1') }
    let!(:book2) { create(:book, title: 'Test Book 2', author: 'Author 2') }
    let!(:book3) { create(:book, title: 'Test Book 3', author: 'Author 3') }

    context 'without authentication' do
      it 'allows access to book listing' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(json_response['books']).to be_present

        # Check that our specific books are included (instead of exact count)
        book_titles = json_response['books'].map { |book| book['title'] }
        expect(book_titles).to include('Test Book 1', 'Test Book 2', 'Test Book 3')
        expect(json_response['books'].length).to be >= 3
      end
    end

    context 'with search parameters' do
      let!(:fiction_book) { create(:book, genre: 'Fiction', title: 'Great Fiction') }
      let!(:science_book) { create(:book, genre: 'Science', author: 'Neil deGrasse Tyson') }

      it 'filters by search query' do
        get :index, params: { search: 'Fiction' }
        expect(response).to have_http_status(:ok)
        titles = json_response['books'].map { |book| book['title'] }
        expect(titles).to include(fiction_book.title)
      end

      it 'filters by genre' do
        get :index, params: { genre: 'Science' }
        expect(response).to have_http_status(:ok)
        genres = json_response['books'].map { |book| book['genre'] }
        expect(genres).to all(eq('Science'))
      end

      it 'filters by author' do
        get :index, params: { author: 'Tyson' }
        expect(response).to have_http_status(:ok)
        authors = json_response['books'].map { |book| book['author'] }
        expect(authors).to include(science_book.author)
      end
    end

    context 'with pagination' do
      before { create_list(:book, 25) }

      it 'paginates results' do
        get :index, params: { page: 1, per_page: 10 }
        expect(response).to have_http_status(:ok)
        expect(json_response['books'].length).to eq(10)
        expect(json_response['pagination']['current_page']).to eq(1)
        expect(json_response['pagination']['per_page']).to eq(10)
      end
    end
  end

  describe 'GET #show' do
    let(:book) { create(:book) }

    context 'without authentication' do
      it 'allows access to book details' do
        get :show, params: { id: book.id }
        expect(response).to have_http_status(:ok)
        expect(json_response['book']['id']).to eq(book.id)
        expect(json_response['book']['title']).to eq(book.title)
      end
    end

    context 'with non-existent book' do
      it 'returns not found' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Book not found')
      end
    end
  end

  describe 'GET #search' do
    let!(:programming_book) { create(:book, title: 'Unique Test Programming Book', genre: 'Programming', author: 'Bob Martin', publisher: 'Prentice Hall') }
    let!(:fiction_book) { create(:book, title: 'Great Gatsby', genre: 'Fiction', author: 'Scott Fitzgerald', publisher: 'Scribner') }

    it 'searches books by query' do
      get :search, params: { q: 'Unique Test Programming' }
      expect(response).to have_http_status(:ok)
      expect(json_response['books'].length).to eq(1)
      expect(json_response['search_query']).to eq('Unique Test Programming')
      expect(json_response['results_count']).to eq(1)
    end

    it 'returns error for empty query' do
      get :search, params: { q: '' }
      expect(response).to have_http_status(:bad_request)
      expect(json_response['error']).to eq('Search query is required')
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        title: 'New Book',
        author: 'New Author',
        isbn: '9781234567890',
        genre: 'Fiction',
        total_copies: 5,
        available_copies: 5
      }
    end

    context 'when user is a librarian' do
      before { login_librarian }

      it 'creates a new book with valid attributes' do
        expect {
          post :create, params: valid_attributes
        }.to change(Book, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['message']).to eq('Book created successfully')
        expect(json_response['book']['title']).to eq('New Book')
      end

      it 'returns errors with invalid attributes' do
        post :create, params: { title: '' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Book creation failed')
        expect(json_response['details']).to be_present
      end

      it 'prevents duplicate ISBN' do
        create(:book, isbn: '9781234567890')
        post :create, params: valid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['details']).to include('Isbn has already been taken')
      end
    end

    context 'when user is a member' do
      before { login_member }

      it 'denies access' do
        post :create, params: valid_attributes
        expect_forbidden_response
      end
    end

    context 'when user is not authenticated' do
      it 'requires authentication' do
        post :create, params: valid_attributes
        expect_unauthorized_response
      end
    end
  end

  describe 'PATCH #update' do
    let(:book) { create(:book) }
    let(:update_attributes) { { title: 'Updated Title', total_copies: 10 } }

    context 'when user is a librarian' do
      before { login_librarian }

      it 'updates the book with valid attributes' do
        patch :update, params: { id: book.id }.merge(update_attributes)
        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Book updated successfully')
        expect(json_response['book']['title']).to eq('Updated Title')
        expect(book.reload.title).to eq('Updated Title')
      end

      it 'returns errors with invalid attributes' do
        patch :update, params: { id: book.id, title: '' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Book update failed')
      end
    end

    context 'when user is a member' do
      before { login_member }

      it 'denies access' do
        patch :update, params: { id: book.id }.merge(update_attributes)
        expect_forbidden_response
      end
    end

    context 'when user is not authenticated' do
      it 'requires authentication' do
        patch :update, params: { id: book.id }.merge(update_attributes)
        expect_unauthorized_response
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:book) { create(:book) }

    context 'when user is a librarian' do
      before { login_librarian }

      it 'deletes the book' do
        expect {
          delete :destroy, params: { id: book.id }
        }.to change(Book, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Book deleted successfully')
      end
    end

    context 'when user is a member' do
      before { login_member }

      it 'denies access' do
        delete :destroy, params: { id: book.id }
        expect_forbidden_response
      end
    end

    context 'when user is not authenticated' do
      it 'requires authentication' do
        delete :destroy, params: { id: book.id }
        expect_unauthorized_response
      end
    end
  end

  describe 'PATCH #manage_status' do
    let(:book) { create(:book, status: 'available') }

    context 'when user is a librarian' do
      before { login_librarian }

      it 'updates book status with valid status' do
        patch :manage_status, params: { id: book.id, status: 'maintenance' }
        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Book status updated successfully')
        expect(book.reload.status).to eq('maintenance')
      end

      it 'returns error with invalid status' do
        patch :manage_status, params: { id: book.id, status: 'invalid_status' }
        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']).to eq('Invalid status')
        expect(json_response['valid_statuses']).to be_present
      end
    end

    context 'when user is a member' do
      before { login_member }

      it 'denies access' do
        patch :manage_status, params: { id: book.id, status: 'maintenance' }
        expect_forbidden_response
      end
    end
  end

  describe 'response structure' do
    let(:book) { create(:book) }

    it 'includes correct book data structure' do
      get :show, params: { id: book.id }

      book_data = json_response['book']
      expect(book_data).to include(
        'id', 'title', 'author', 'genre', 'status',
        'available_copies', 'total_copies', 'available',
        'isbn', 'description', 'publication_year', 'publisher'
      )
    end

    it 'includes helper methods in detailed view' do
      get :show, params: { id: book.id }

      book_data = json_response['book']
      expect(book_data).to include('full_title', 'published_info')
    end
  end
end
