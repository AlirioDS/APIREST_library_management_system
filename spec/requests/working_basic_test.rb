require 'rails_helper'

RSpec.describe "Working Basic Test", type: :request do
  # Set proper host for Rails 8 host authorization
  before { host! 'localhost' }
  
  describe "POST /api/v1/auth/register" do
    it "creates a new user successfully" do
      post '/api/v1/auth/register', 
        params: {
          email_address: 'working@test.com',
          password: 'password123',
          password_confirmation: 'password123',
          first_name: 'Working',
          last_name: 'Test'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }

      puts "Status: #{response.status}"
      puts "Body: #{response.body[0..200]}" # First 200 chars
      
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['message']).to eq('Registration successful')
    end
  end

  describe "GET /api/v1/books" do
    let!(:book) { create(:book, title: 'Working Book') }

    it "lists books successfully" do
      get '/api/v1/books'

      puts "Books Status: #{response.status}"
      puts "Books Body: #{response.body[0..200]}" # First 200 chars
      
      expect(response).to have_http_status(:ok)
      books = JSON.parse(response.body)['books']
      expect(books).to be_an(Array)
    end
  end
end 
