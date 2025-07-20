require 'rails_helper'

RSpec.describe Api::V1::AuthenticationController, type: :controller do
  # Clean up test data before running any tests  
  before(:all) do
    User.where(email_address: 'test@example.com').destroy_all
  end
  
  describe 'POST #login' do
    let!(:user) { create(:user, email_address: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'authenticates user and returns JWT tokens' do
        post :login, params: { 
          email_address: 'test@example.com', 
          password: 'password123' 
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Login successful')
        expect(json_response['token']).to be_present
        expect(json_response['refresh_token']).to be_present
        
        user_data = json_response['user']
        expect(user_data['id']).to eq(user.id)
        expect(user_data['email_address']).to eq(user.email_address)
        expect(user_data['role']).to eq(user.role)
      end

      it 'updates last_signed_in_at timestamp' do
        expect {
          post :login, params: { 
            email_address: 'test@example.com', 
            password: 'password123' 
          }
        }.to change { user.reload.last_signed_in_at }
      end

      it 'generates valid JWT token' do
        post :login, params: { 
          email_address: 'test@example.com', 
          password: 'password123' 
        }

        token = json_response['token']
        payload = User.decode_jwt_token(token)
        
        expect(payload).to be_present
        expect(payload['user_id']).to eq(user.id)
        expect(payload['email']).to eq(user.email_address)
        expect(payload['role']).to eq(user.role)
      end
    end

    context 'with invalid credentials' do
      it 'returns error for wrong password' do
        post :login, params: { 
          email_address: 'test@example.com', 
          password: 'wrongpassword' 
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid email or password')
        expect(json_response['token']).not_to be_present
      end

      it 'returns error for non-existent user' do
        post :login, params: { 
          email_address: 'nonexistent@example.com', 
          password: 'password123' 
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid email or password')
      end

      it 'returns error for missing credentials' do
        post :login, params: { email_address: 'test@example.com' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid email or password')
      end
    end
  end

  describe 'POST #register' do
    let(:valid_registration_params) do
      {
        email_address: 'newuser@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        first_name: 'John',
        last_name: 'Doe'
      }
    end

    context 'with valid parameters' do
      it 'creates new user and returns JWT tokens' do
        expect {
          post :register, params: valid_registration_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['message']).to eq('Registration successful')
        expect(json_response['token']).to be_present
        expect(json_response['refresh_token']).to be_present

        user_data = json_response['user']
        expect(user_data['email_address']).to eq('newuser@example.com')
        expect(user_data['first_name']).to eq('John')
        expect(user_data['last_name']).to eq('Doe')
        expect(user_data['role']).to eq('member')
      end

      it 'sets default role as member' do
        post :register, params: valid_registration_params

        user = User.find_by(email_address: 'newuser@example.com')
        expect(user.role).to eq('member')
      end
    end

    context 'with invalid parameters' do
      it 'returns error for duplicate email' do
        create(:user, email_address: 'existing@example.com')
        
        post :register, params: valid_registration_params.merge(
          email_address: 'existing@example.com'
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include('Email address has already been taken')
      end

      it 'returns error for password mismatch' do
        post :register, params: valid_registration_params.merge(
          password_confirmation: 'differentpassword'
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include("Password confirmation doesn't match Password")
      end

      it 'returns error for short password' do
        post :register, params: valid_registration_params.merge(
          password: '123',
          password_confirmation: '123'
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['details']).to include('Password is too short (minimum is 8 characters)')
      end

      it 'returns error for missing required fields' do
        post :register, params: { password: 'password123' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include("Email address can't be blank")
      end
    end
  end

  describe 'POST #refresh' do
    let!(:user) { create(:user) }

    context 'with valid refresh token' do
      it 'returns new access token' do
        refresh_token = user.generate_refresh_token

        post :refresh, params: { refresh_token: refresh_token }

        expect(response).to have_http_status(:ok)
        expect(json_response['token']).to be_present
        expect(json_response['refresh_token']).to be_present
        expect(json_response['token']).to be_present
        expect(json_response['refresh_token']).to be_present
      end
    end

    context 'with invalid refresh token' do
      it 'returns error for invalid token' do
        post :refresh, params: { refresh_token: 'invalid.token.here' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid refresh token')
      end

      it 'returns error for missing token' do
        post :refresh, params: {}

        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']).to eq('Refresh token required')
      end

      it 'returns error for non-refresh token' do
        access_token = user.generate_jwt_token
        post :refresh, params: { refresh_token: access_token }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid refresh token')
      end
    end
  end

  describe 'DELETE #logout' do
    let!(:user) { create(:user) }

    context 'when authenticated' do
      before { login_user(user) }

      it 'logs out user successfully' do
        delete :logout

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Logout successful')
      end
    end

    context 'when not authenticated' do
      it 'requires authentication' do
        delete :logout
        expect_unauthorized_response
      end
    end
  end

  describe 'GET #me' do
    let!(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    context 'when authenticated' do
      before { login_user(user) }

      it 'returns current user information' do
        get :me

        expect(response).to have_http_status(:ok)
        user_data = json_response['user']
        expect(user_data['id']).to eq(user.id)
        expect(user_data['email_address']).to eq(user.email_address)
        expect(user_data['first_name']).to eq('John')
        expect(user_data['last_name']).to eq('Doe')
        expect(user_data['role']).to eq(user.role)
      end
    end

    context 'when not authenticated' do
      it 'requires authentication' do
        get :me
        expect_unauthorized_response
      end
    end
  end

  describe 'JWT token validation' do
    let!(:user) { create(:user) }

    it 'validates token expiration' do
      expired_token = JWT.encode(
        { 
          user_id: user.id, 
          email: user.email_address,
          role: user.role,
          exp: 1.hour.ago.to_i 
        },
        User.jwt_secret_key,
        'HS256'
      )

      request.headers['Authorization'] = "Bearer #{expired_token}"
      get :me

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Invalid or expired token')
    end

    it 'validates token signature' do
      invalid_token = JWT.encode(
        { user_id: user.id, email: user.email_address },
        'wrong_secret',
        'HS256'
      )

      request.headers['Authorization'] = "Bearer #{invalid_token}"
      get :me

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Invalid or expired token')
    end

    it 'validates user existence' do
      valid_token = JWT.encode(
        { 
          user_id: 99999, 
          email: 'nonexistent@example.com',
          role: 'member',
          exp: 1.hour.from_now.to_i 
        },
        User.jwt_secret_key,
        'HS256'
      )

      request.headers['Authorization'] = "Bearer #{valid_token}"
      get :me

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Invalid token - user not found')
    end
  end

  describe 'response structure' do
    let!(:user) { create(:user) }

    it 'includes consistent user data structure' do
      post :login, params: { 
        email_address: user.email_address, 
        password: 'password123' 
      }

      user_data = json_response['user']
      expected_fields = %w[id email_address first_name last_name role last_signed_in_at]
      expect(user_data.keys).to match_array(expected_fields)
    end

    it 'excludes sensitive information' do
      post :login, params: { 
        email_address: user.email_address, 
        password: 'password123' 
      }

      user_data = json_response['user']
      expect(user_data.keys).not_to include('password_digest')
    end
  end
end 
