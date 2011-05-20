class ApplicationController < ActionController::Base

  protect_from_forgery
  before_filter :authenticate
  before_filter :set_locale
  
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

  def set_locale
    logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
    I18n.locale = extract_locale_from_accept_language_header
    logger.debug "* Locale set to '#{I18n.locale}'"
#    I18n.locale = :en
  end

  private
  def extract_locale_from_accept_language_header
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  end


end
