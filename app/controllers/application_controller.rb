class ApplicationController < ActionController::Base

  protect_from_forgery
  before_filter :authenticate
  
  def authenticate
    skip_auth_for = {
      'sessions'        => true,
      'page#thankyou'   => true,
      'page#index'      => true
    }
    authenticate_user! unless check_for_presence(skip_auth_for)
  end

  def check_for_presence(data)
    data.has_key?(controller_name) or 
    data.has_key?([controller_name, action_name].join("#")) or
    devise_controller?
  end

end
