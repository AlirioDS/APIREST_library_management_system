require 'rails_helper'

RSpec.describe "Basic Authentication", type: :request do
  describe "POST /api/v1/auth/register" do
    it "creates a new user successfully" do
      post '/api/v1/auth/register',
        params: {
          email_address: 'basic@test.com',
          password: 'password123',
          password_confirmation: 'password123',
          first_name: 'Basic',
          last_name: 'User'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['message']).to eq('Registration successful')
      expect(JSON.parse(response.body)['token']).to be_present
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email_address: 'login@test.com', password: 'password123') }

    it "logs in existing user successfully" do
      post '/api/v1/auth/login',
        params: {
          email_address: 'login@test.com',
          password: 'password123'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq('Login successful')
      expect(JSON.parse(response.body)['token']).to be_present
    end

    it "fails with wrong password" do
      post '/api/v1/auth/login',
        params: {
          email_address: 'login@test.com',
          password: 'wrongpassword'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq('Invalid email or password')
    end
  end

  describe "GET /api/v1/books" do
    let!(:book) { create(:book, title: 'Test Book', author: 'Test Author') }

    it "lists books without authentication" do
      get '/api/v1/books'

      expect(response).to have_http_status(:ok)
      books = JSON.parse(response.body)['books']
      expect(books).to be_an(Array)
      expect(books.first['title']).to eq('Test Book')
    end
  end
end
