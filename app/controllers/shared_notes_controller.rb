# Read-only view of a note for anyone with its share link. A link with a
# password asks for it once per browser session.
class SharedNotesController < ApplicationController
  include AttachmentServing

  # Per process; enough to slow down guessing a share password.
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  UNLOCKED_LIMIT = 20

  skip_before_action :authenticate_user!
  before_action :set_private_headers
  before_action :set_note
  before_action :require_unlocked, except: :unlock

  rate_limit to: 10, within: 5.minutes, only: :unlock, store: RATE_LIMIT_STORE,
             by: -> { "#{request.remote_ip}:#{params[:token]}" },
             with: -> {
               flash.now[:alert] = t("flash.share_too_many_attempts")
               render :password, status: :too_many_requests
             }

  def show
    @attachments = @note.note_attachments.with_attached_file
  end

  def unlock
    if !@note.share_password? || @note.authenticate_share_password(params[:password].to_s)
      remember_unlocked
      redirect_to shared_note_path(@note.share_token)
    else
      flash.now[:alert] = t("flash.share_wrong_password")
      render :password, status: :unprocessable_content
    end
  end

  def download_file
    send_attachment @note.note_attachments.find(params[:attachment_id])
  end

  def preview_file
    send_attachment_preview @note.note_attachments.find(params[:attachment_id])
  end

  private

  # The token is the secret: keep it out of Referer headers sent to other
  # sites, caches and search engines. "no-referrer" would make browsers send
  # Origin: null on the password form, which fails Rails' CSRF origin check.
  def set_private_headers
    response.headers["Referrer-Policy"] = "same-origin"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
    response.headers["Cache-Control"] = "no-store"
  end

  def set_note
    @note = Note.find_by(share_token: params[:token].to_s)
    render :missing, status: :not_found unless @note
  end

  def require_unlocked
    return if !@note.share_password? || unlocked?

    if action_name == "show"
      render :password
    else
      redirect_to shared_note_path(@note.share_token)
    end
  end

  # The session remembers a fingerprint of the password hash, so changing the
  # password or the link locks the note again.
  def unlock_key
    Digest::SHA256.hexdigest(@note.share_password_digest.to_s)[0, 16]
  end

  def unlocked?
    session.dig(:unlocked_shares, @note.share_token) == unlock_key
  end

  def remember_unlocked
    unlocked = (session[:unlocked_shares] || {}).to_h.except(@note.share_token)
    unlocked[@note.share_token] = unlock_key
    session[:unlocked_shares] = unlocked.to_a.last(UNLOCKED_LIMIT).to_h
  end
end
