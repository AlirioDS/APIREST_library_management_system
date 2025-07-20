class WebApplicationController < ActionController::Base
  include Authentication

  # Web-specific configurations can go here
  protect_from_forgery with: :exception

  before_action :require_authentication
end
