module ControllerHelpers
  def authenticate_as(user)
    token = user.generate_jwt_token
    request.headers['Authorization'] = "Bearer #{token}"
  end

  def authenticate_as_librarian
    librarian = create(:user, :librarian)
    authenticate_as(librarian)
    librarian
  end

  def authenticate_as_member
    member = create(:user, :member)
    authenticate_as(member)
    member
  end
end
