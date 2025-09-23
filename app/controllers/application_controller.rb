class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
    nil
  end

  def logged_in?
    current_user.present?
  end

  def authenticate_user!
    unless logged_in?
      redirect_to login_path, alert: 'You must be logged in to access this page'
    end
  end

  # For development/testing, auto-create and login a user
  before_action :ensure_test_user, if: :development_or_test?

  private

  def development_or_test?
    Rails.env.development? || Rails.env.test?
  end

  def ensure_test_user
    unless current_user
      # Create a test tenant and user for development
      tenant = Tenant.first_or_create!(
        name: 'Test Company',
        subdomain: 'test',
        plan: 'enterprise',
        status: 'active'
      )

      user = tenant.users.first_or_create!(
        email: 'test@example.com',
        name: 'Test User',
        password: 'password123',
        status: 'active'
      )

      session[:user_id] = user.id
      @current_user = user
    end
  end
end
