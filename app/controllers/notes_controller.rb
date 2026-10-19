class NotesController < ApplicationController
  include AttachmentServing

  before_action :set_note, only: %i[show edit update destroy download_file preview_file delete_file share unshare
                                   history restore]

  # Orders of the board, in the order the sort button cycles through them.
  SORTS = {
    "created_asc" => { created_at: :asc, id: :asc },
    "created_desc" => { created_at: :desc, id: :desc },
    "updated_desc" => { updated_at: :desc, id: :desc },
    "updated_asc" => { updated_at: :asc, id: :asc }
  }.freeze

  before_action :set_sort, only: %i[index by_tag]

  # The search box in the menu bar sends q (title or description) and color.
  def index
    @query = params[:q].to_s.strip
    @color = params[:color].presence_in(Note::COLORS)
    @notes = Note.includes(:finance_entries).order(SORTS.fetch(@sort))
    @notes = @notes.search(@query) if @query.present?
    @notes = @notes.where(color: @color) if @color
  end

  def show
  end

  def new
    @note = Note.new
  end

  def create
    @note = Note.new(note_params.merge(author: current_user.display_name))
    respond_to do |format|
      if @note.save
        format.html { redirect_to notes_path, notice: t("flash.note_created") }
        format.json { render json: autosave_json, status: :created }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: { error: @note.errors.full_messages.to_sentence }, status: :unprocessable_content }
      end
    end
  end

  def edit
  end

  # The show page has three forms that all submit here: title and description,
  # a finance entry (params[:finance]), and file uploads (note[attachments][]).
  # The colour menu also submits here (note[color]).
  def update
    @note.assign_attributes(note_params.merge(updated_from: current_user.display_name))
    if params[:finance]
      @note.finance_entries.build(finance_params.merge(author: current_user.display_name))
    end
    Array(params.dig(:note, :attachments)).compact_blank.each do |file|
      @note.note_attachments.build(file: file, comment: params.dig(:note, :attachment_comment))
    end

    respond_to do |format|
      if @note.save
        format.html { redirect_to note_url(@note) }
        format.json { render json: autosave_json }
      else
        format.html do
          flash.now[:alert] = errors_for(@note).to_sentence
          render :show, status: :unprocessable_content
        end
        format.json { render json: { error: errors_for(@note).to_sentence }, status: :unprocessable_content }
      end
    end
  end

  def by_tag
    @tag = params[:id]
    @notes = Note.tagged_with(@tag).order(SORTS.fetch(@sort))
  end

  # Attachments are streamed through these actions, not Active Storage's public
  # routes, so reading a file requires a signed-in user.
  def download_file
    send_attachment @note.note_attachments.find(params[:attachment_id])
  end

  def preview_file
    send_attachment_preview @note.note_attachments.find(params[:attachment_id])
  end

  def delete_file
    attachment = @note.note_attachments.find(params[:attachment_id])
    attachment.destroy
    redirect_to note_url(@note), notice: t("flash.file_deleted", filename: attachment.filename)
  end

  # Creates a new share link (optionally with a password), replacing any old one.
  def share
    if @note.share(password: params[:share_password])
      redirect_to note_url(@note, anchor: "sharing"), notice: t("flash.note_shared")
    else
      redirect_to note_url(@note, anchor: "sharing"), alert: @note.errors.full_messages.to_sentence
    end
  end

  def unshare
    @note.unshare!
    redirect_to note_url(@note, anchor: "sharing"), notice: t("flash.note_unshared")
  end

  HISTORY_LIMIT = 200

  # The time capsule: the latest HISTORY_LIMIT versions, oldest first, with
  # ?v=<version id> in front (default: the newest).
  def history
    @versions = @note.versions.reorder(created_at: :desc, id: :desc).limit(HISTORY_LIMIT).to_a.reverse
    @selected = @versions.index { |version| version.id.to_s == params[:v].to_s } || (@versions.size - 1)
  end

  def restore
    version = @note.versions.find(params[:version_id])
    if @note.restore(version)
      redirect_to note_url(@note), notice: t("flash.version_restored", time: l(version.created_at, format: :long))
    else
      redirect_to history_note_url(@note, v: version.id), alert: @note.errors.full_messages.to_sentence
    end
  end

  def destroy
    @note.destroy
    redirect_to notes_path, notice: t("flash.note_deleted", title: @note.title)
  end

  private

  # A note deleted while its page is open: the live refresh (or a reload)
  # lands on the board with a notice instead of a 404 page.
  def set_note
    @note = Note.find_by(id: params[:id])
    return if @note
    raise ActiveRecord::RecordNotFound unless request.get? && action_name.in?(%w[show edit])

    redirect_to notes_path, alert: t("flash.note_gone")
  end

  # ?sort= (from the sort button without JavaScript) wins and is remembered
  # in the "sort" cookie, which the script also sets.
  def set_sort
    if (sort = params[:sort].presence_in(SORTS.keys))
      cookies.permanent[:sort] = { value: sort, same_site: :lax }
    end
    @sort = sort || cookies[:sort].presence_in(SORTS.keys) || SORTS.keys.first
  end

  def note_params
    params.fetch(:note, {}).permit(:title, :description, :tag_list, :visited_on, :color, :markdown, :wide)
  end

  def finance_params
    params.expect(finance: %i[date amount comment])
  end

  # Answer to the note form's automatic saves (application.js).
  # For Markdown notes the rendered text comes along, so the page can show it
  # again when the note locks.
  def autosave_json
    json = { url: note_path(@note), saved_at: l(@note.updated_at, format: "%H:%M") }
    json[:html] = helpers.render_markdown(@note.description, interactive: true) if @note.markdown?
    json
  end

  def errors_for(note)
    note.errors.full_messages +
      note.finance_entries.flat_map { |entry| entry.errors.full_messages } +
      note.note_attachments.flat_map { |attachment| attachment.errors.full_messages }
  end
end
