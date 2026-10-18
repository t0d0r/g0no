module Admin
  # Lets an admin revoke any note's share link.
  class SharesController < BaseController
    def destroy
      note = Note.find(params[:id])
      note.unshare!
      redirect_to admin_root_path, notice: t("flash.share_revoked", title: note.title)
    end
  end
end
