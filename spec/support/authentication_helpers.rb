module AuthenticationHelpers
  def login_user(user)
    @current_user = user
    if defined?(controller)
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:authenticate_user!).and_return(true)
    end
  end

  def login_librarian
    librarian = create(:user, :librarian)
    login_user(librarian)
    librarian
  end

  def login_member
    member = create(:user, :member)
    login_user(member)
    member
  end

  def auth_headers_for(user)
    token = user.generate_jwt_token
    { 'Authorization' => "Bearer #{token}" }
  end

  def json_response
    JSON.parse(response.body)
  end

  def expect_unauthorized_response
    expect(response).to have_http_status(:unauthorized)
    expect(json_response['error']).to be_present
  end

  def expect_forbidden_response
    expect(response).to have_http_status(:forbidden)
    expect(json_response['error']).to be_present
  end

  def expect_success_response(status = :ok)
    expect(response).to have_http_status(status)
  end

  def expect_error_response(status, error_key = 'error')
    expect(response).to have_http_status(status)
    expect(json_response[error_key]).to be_present
  end
end
