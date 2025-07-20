class Api::V1::AuthenticationController < ApplicationController
  before_action :authenticate_user!, only: [ :logout, :me ]

  # POST /api/v1/auth/login
  def login
    user = User.find_by(email_address: params[:email_address])

    if user&.authenticate(params[:password])
      user.update(last_signed_in_at: Time.current)

      render json: {
        message: "Login successful",
        user: user_data(user),
        token: user.generate_jwt_token,
        refresh_token: user.generate_refresh_token
      }, status: :ok
    else
      render json: {
        error: "Invalid email or password"
      }, status: :unauthorized
    end
  end

  # POST /api/v1/auth/register
  def register
    user = User.new(user_params)

    if user.save
      render json: {
        message: "Registration successful",
        user: user_data(user),
        token: user.generate_jwt_token,
        refresh_token: user.generate_refresh_token
      }, status: :created
    else
      render json: {
        error: "Registration failed",
        details: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/auth/refresh
  def refresh
    refresh_token = params[:refresh_token]

    if refresh_token.blank?
      return render json: { error: "Refresh token required" }, status: :bad_request
    end

    payload = User.decode_jwt_token(refresh_token)

    if payload && payload["type"] == "refresh"
      user = User.find_by(id: payload["user_id"])

      if user
        render json: {
          token: user.generate_jwt_token,
          refresh_token: user.generate_refresh_token
        }, status: :ok
      else
        render json: { error: "Invalid refresh token" }, status: :unauthorized
      end
    else
      render json: { error: "Invalid refresh token" }, status: :unauthorized
    end
  end

  # DELETE /api/v1/auth/logout
  def logout
    # For JWT, logout is mainly client-side (removing token)
    # You could implement token blacklisting here if needed
    render json: { message: "Logout successful" }, status: :ok
  end

  # GET /api/v1/auth/me
  def me
    render json: {
      user: user_data(current_user)
    }, status: :ok
  end

  private

  def user_params
    permitted = [ :email_address, :password, :password_confirmation, :first_name, :last_name ]
    # Only librarians can set roles during registration (for creating other librarians)
    permitted << :role if current_user&.librarian?
    params.permit(permitted)
  end

  def user_data(user)
    {
      id: user.id,
      email_address: user.email_address,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      last_signed_in_at: user.last_signed_in_at
    }
  end
end
