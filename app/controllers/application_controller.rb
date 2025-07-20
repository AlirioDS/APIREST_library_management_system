class ApplicationController < ActionController::API
  include Pundit::Authorization
  
  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized
  
  protected
  
  def authenticate_user!
    token = extract_token_from_header
    
    if token.blank?
      render json: { error: 'Authentication token required' }, status: :unauthorized
      return
    end
    
    payload = User.decode_jwt_token(token)
    
    if payload
      @current_user = User.find_by(id: payload['user_id'])
      
      unless @current_user
        render json: { error: 'Invalid token - user not found' }, status: :unauthorized
      end
    else
      render json: { error: 'Invalid or expired token' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
  
  def user_signed_in?
    current_user.present?
  end
  
  # Optional authentication - sets current_user if token provided, but doesn't fail if not
  def set_current_user_optional
    token = extract_token_from_header
    
    if token.present?
      payload = User.decode_jwt_token(token)
      @current_user = User.find_by(id: payload['user_id']) if payload
    end
    
    # Continue regardless of authentication status
  end
  
  private
  
  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header&.start_with?('Bearer ')
    
    auth_header.split(' ').last
  end
  
  def handle_unauthorized
    render json: { 
      error: 'You are not authorized to perform this action' 
    }, status: :forbidden
  end
end
