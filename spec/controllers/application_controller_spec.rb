require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    before_action :authenticate_user!
    
    def index
      render json: { user_id: current_user&.id }
    end
  end

  let(:user) { create(:user) }

  describe 'JWT authentication' do
    context 'with valid token' do
      before do
        token = user.generate_jwt_token
        request.headers['Authorization'] = "Bearer #{token}"
      end

      it 'authenticates user' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(json_response['user_id']).to eq(user.id)
      end
    end

    context 'without token' do
      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid token' do
      before do
        request.headers['Authorization'] = 'Bearer invalid.token.here'
      end

      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end 
