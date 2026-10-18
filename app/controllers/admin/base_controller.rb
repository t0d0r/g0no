module Admin
  # Pages under /admin are for users with the admin flag only.
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      redirect_to root_path, alert: t("flash.admin_only") unless current_user.admin?
    end
  end
end
