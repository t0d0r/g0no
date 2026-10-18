module Users
  # Sign-up is closed when REGISTRATION_OPEN is false (the production
  # default); administrators then create users at /admin. Editing your own
  # account stays as Devise has it.
  class RegistrationsController < Devise::RegistrationsController
    before_action :require_open_registration, only: %i[new create]

    private

    def require_open_registration
      return if Rails.configuration.x.registration_open

      redirect_to new_user_session_path, alert: t("flash.registration_closed")
    end
  end
end
