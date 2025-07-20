class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :update, :destroy, :change_role]

  # GET /api/v1/users
  def index
    @users = policy_scope(User)
    authorize User
    
    render json: {
      users: @users.map { |user| user_data(user) }
    }, status: :ok
  end

  # GET /api/v1/users/:id
  def show
    authorize @user
    
    render json: {
      user: user_data(@user)
    }, status: :ok
  end

  # POST /api/v1/users
  def create
    @user = User.new(user_params)
    authorize @user
    
    if @user.save
      render json: {
        message: 'User created successfully',
        user: user_data(@user)
      }, status: :created
    else
      render json: {
        error: 'User creation failed',
        details: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/users/:id
  def update
    authorize @user
    
    if @user.update(user_update_params)
      render json: {
        message: 'User updated successfully',
        user: user_data(@user)
      }, status: :ok
    else
      render json: {
        error: 'User update failed',
        details: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/users/:id
  def destroy
    authorize @user
    
    if @user.destroy
      render json: {
        message: 'User deleted successfully'
      }, status: :ok
    else
      render json: {
        error: 'User deletion failed'
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/users/:id/change_role
  def change_role
    authorize @user, :change_role?
    
    if @user.update(role: params[:role])
      render json: {
        message: 'User role updated successfully',
        user: user_data(@user)
      }, status: :ok
    else
      render json: {
        error: 'Role update failed',
        details: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def user_params
    permitted = [:email_address, :password, :password_confirmation, :first_name, :last_name]
    permitted << :role if current_user&.librarian?
    params.permit(permitted)
  end

  def user_update_params
    permitted = [:first_name, :last_name]
    permitted << :email_address if current_user&.librarian? || current_user == @user
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
      last_signed_in_at: user.last_signed_in_at,
      created_at: user.created_at
    }
  end
end 
