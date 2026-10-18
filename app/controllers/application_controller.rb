class ApplicationController < ActionController::Base
  around_action :switch_locale
  before_action :authenticate_user!, unless: :devise_controller?
  before_action { Current.user = current_user }

  private

  def switch_locale(&action)
    I18n.with_locale(locale_from_accept_language || I18n.default_locale, &action)
  end

  # Uses the first language in Accept-Language when the app has a translation for it.
  def locale_from_accept_language
    request.env["HTTP_ACCEPT_LANGUAGE"].to_s.scan(/^[a-z]{2}/).first
      .presence_in(I18n.available_locales.map(&:to_s))
  end
end
