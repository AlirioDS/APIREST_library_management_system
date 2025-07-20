require 'rails_helper'

RSpec.describe 'Library Management API', type: :request do
  describe 'Complete Library Workflow Integration' do
    let(:librarian) { create(:user, :librarian) }
    let(:member) { create(:user, :member) }

    describe 'Authentication Flow' do
      it 'allows user registration and login' do
        # Register new member
        post '/api/v1/auth/register',
          params: {
            email_address: 'newmember@library.com',
            password: 'password123',
            password_confirmation: 'password123',
            first_name: 'New',
            last_name: 'Member'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:created)
        expect(json_response['token']).to be_present
        expect(json_response['user']['role']).to eq('member')

        # Login with new credentials
        post '/api/v1/auth/login', params: {
          email_address: 'newmember@library.com',
          password: 'password123'
        }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['token']).to be_present
      end

      it 'handles token refresh correctly' do
        post '/api/v1/auth/login', params: {
          email_address: member.email_address,
          password: 'password123'
        }

        refresh_token = json_response['refresh_token']

        # Use refresh token to get new access token
        post '/api/v1/auth/refresh', params: {
          refresh_token: refresh_token
        }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['token']).to be_present
      end
    end

    describe 'Book Management Workflow' do
      it 'allows complete book CRUD operations by librarians' do
        # Login as librarian
        post '/api/v1/auth/login', params: {
          email_address: librarian.email_address,
          password: 'password123'
        }, as: :json
        token = json_response['token']
        headers = { 'Authorization' => "Bearer #{token}" }

        # Create a book
        post '/api/v1/books', params: {
          title: 'Test Book',
          author: 'Test Author',
          isbn: '9781234567890',
          genre: 'Fiction',
          total_copies: 5,
          available_copies: 5
        }, headers: headers, as: :json

        expect(response).to have_http_status(:created)
        book_id = json_response['book']['id']

        # Read the book
        get "/api/v1/books/#{book_id}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response['book']['title']).to eq('Test Book')

        # Update the book
        patch "/api/v1/books/#{book_id}", params: {
          total_copies: 8,
          description: 'Updated description'
        }, headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response['book']['total_copies']).to eq(8)

        # Search for the book
        get '/api/v1/books/search', params: { q: 'Test Book' }
        expect(response).to have_http_status(:ok)
        expect(json_response['books']).not_to be_empty

        # Delete the book
        delete "/api/v1/books/#{book_id}", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'Borrowing Workflow' do
      let!(:available_book) { create(:book, :available) }

      it 'allows complete borrowing and returning cycle' do
        # Member login
        post '/api/v1/auth/login', params: {
          email_address: member.email_address,
          password: 'password123'
        }, as: :json
        member_token = json_response['token']
        member_headers = { 'Authorization' => "Bearer #{member_token}" }

        # Librarian login
        post '/api/v1/auth/login', params: {
          email_address: librarian.email_address,
          password: 'password123'
        }, as: :json
        librarian_token = json_response['token']
        librarian_headers = { 'Authorization' => "Bearer #{librarian_token}" }

        # Member borrows book
        initial_copies = available_book.available_copies
        post "/api/v1/books/#{available_book.id}/borrow", headers: member_headers

        expect(response).to have_http_status(:created)
        borrowing_id = json_response['borrowing']['id']
        expect(json_response['borrowing']['status']).to eq('borrowed')

        # Verify book availability decreased
        available_book.reload
        expect(available_book.available_copies).to eq(initial_copies - 1)

        # Member views their borrowings
        get '/api/v1/borrowings', headers: member_headers
        expect(response).to have_http_status(:ok)
        expect(json_response['borrowings'].length).to eq(1)

        # Member tries to borrow same book again (should fail)
        post "/api/v1/books/#{available_book.id}/borrow", headers: member_headers
        expect(response).to have_http_status(:unprocessable_entity)

        # Librarian processes return
        patch "/api/v1/borrowings/#{borrowing_id}/return", headers: librarian_headers
        expect(response).to have_http_status(:ok)
        expect(json_response['borrowing']['status']).to eq('returned')

        # Verify book availability increased
        available_book.reload
        expect(available_book.available_copies).to eq(initial_copies)
      end
    end

    describe 'Dashboard Workflows' do
      before do
        create_list(:book, 5)
        create_list(:borrowing, 3, user: member)
        create(:borrowing, :overdue, user: member)
      end

      it 'provides librarian dashboard with statistics' do
        # Librarian login
        post '/api/v1/auth/login', params: {
          email_address: librarian.email_address,
          password: 'password123'
        }, as: :json
        token = json_response['token']
        headers = { 'Authorization' => "Bearer #{token}" }

        # Access librarian dashboard
        get '/api/v1/dashboard/librarian', headers: headers
        expect(response).to have_http_status(:ok)

        dashboard = json_response['dashboard']
        expect(dashboard['overview']['total_books']).to eq(Book.count)
        expect(dashboard['overview']['borrowed_books']).to eq(Borrowing.active.count)
        expect(dashboard['overview']['overdue_books']).to eq(Borrowing.overdue.count)
      end

      it 'provides member dashboard with personal information' do
        # Member login
        post '/api/v1/auth/login', params: {
          email_address: member.email_address,
          password: 'password123'
        }, as: :json
        token = json_response['token']
        headers = { 'Authorization' => "Bearer #{token}" }

        # Access member dashboard
        get '/api/v1/dashboard/member', headers: headers
        expect(response).to have_http_status(:ok)

        dashboard = json_response['dashboard']
        expect(dashboard['overview']['total_books_borrowed']).to eq(member.borrowings.count)
        expect(dashboard['overview']['currently_borrowed']).to eq(member.borrowings.active.count)
        expect(dashboard['overview']['overdue_books']).to eq(member.borrowings.overdue.count)
      end
    end

    describe 'Authorization Enforcement' do
      it 'properly enforces role-based access control' do
        # Member login
        post '/api/v1/auth/login', params: {
          email_address: member.email_address,
          password: 'password123'
        }, as: :json
        member_token = json_response['token']
        member_headers = { 'Authorization' => "Bearer #{member_token}" }

        # Member tries to create book (should fail)
        post '/api/v1/books', params: {
          title: 'Unauthorized Book',
          author: 'No Access'
        }, headers: member_headers, as: :json
        expect(response).to have_http_status(:forbidden)

        # Member tries to access librarian dashboard (should fail)
        get '/api/v1/dashboard/librarian', headers: member_headers
        expect(response).to have_http_status(:forbidden)

        # Member tries to return book (should fail)
        borrowing = create(:borrowing, user: member)
        patch "/api/v1/borrowings/#{borrowing.id}/return", headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'Error Handling' do
      it 'handles various error scenarios gracefully' do
        # Invalid authentication
        get '/api/v1/borrowings', headers: { 'Authorization' => 'Bearer invalid.token.here' }
        expect(response).to have_http_status(:unauthorized)

        # Resource not found
        get '/api/v1/books/999999'
        expect(response).to have_http_status(:not_found)

        # Invalid data
        post '/api/v1/auth/register', params: {
          email_address: 'invalid-email',
          password: '123'
        }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['details']).to include('Password is too short (minimum is 8 characters)')
      end
    end

    describe 'Public vs Protected Endpoints' do
      it 'allows public access to book browsing' do
        # Public book listing
        get '/api/v1/books'
        expect(response).to have_http_status(:ok)

        # Public book search
        get '/api/v1/books/search', params: { q: 'fiction' }
        expect(response).to have_http_status(:ok)

        # Public book details
        book = create(:book)
        get "/api/v1/books/#{book.id}"
        expect(response).to have_http_status(:ok)
      end

      it 'protects management operations' do
        # Book creation requires authentication
        post '/api/v1/books', params: { title: 'Test' }, as: :json
        expect(response).to have_http_status(:unauthorized)

        # Borrowing requires authentication
        book = create(:book)
        post "/api/v1/books/#{book.id}/borrow"
        expect(response).to have_http_status(:unauthorized)

        # Dashboard requires authentication
        get '/api/v1/dashboard/member'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
