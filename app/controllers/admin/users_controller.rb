module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[edit update destroy]

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_root_path, notice: t("flash.user_created", name: @user.display_name)
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    # A blank password keeps the current one. Admins cannot remove their own
    # admin flag, so there is always at least one admin.
    def update
      attributes = user_params
      attributes = attributes.except(:password, :password_confirmation) if attributes[:password].blank?
      attributes = attributes.except(:admin) if @user == current_user

      if @user.update(attributes)
        # Devise signs a user out when their password hash changes.
        bypass_sign_in(@user) if @user == current_user
        redirect_to admin_root_path, notice: t("flash.user_updated", name: @user.display_name)
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_root_path, alert: t("flash.user_self_delete")
      else
        @user.destroy
        redirect_to admin_root_path, notice: t("flash.user_deleted", name: @user.display_name)
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.expect(user: %i[username email password password_confirmation admin])
    end
  end
end
