class NotesController < ApplicationController
  before_action :set_note, only: %i[show edit update destroy download_file delete_file]

  def index
    @notes = Note.includes(:finance_entries).order(:created_at)
  end

  def show
  end

  def new
    @note = Note.new
  end

  def create
    @note = Note.new(note_params.merge(author: current_user.display_name))
    if @note.save
      redirect_to notes_path, notice: t("flash.note_created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  # The show page has three forms that all submit here: title and description,
  # a finance entry (params[:finance]), and file uploads (note[attachments][]).
  def update
    @note.assign_attributes(note_params.merge(updated_from: current_user.display_name))
    if params[:finance]
      @note.finance_entries.build(finance_params.merge(author: current_user.display_name))
    end
    Array(params.dig(:note, :attachments)).compact_blank.each do |file|
      @note.note_attachments.build(file: file, comment: params.dig(:note, :attachment_comment))
    end

    if @note.save
      redirect_to note_url(@note)
    else
      flash.now[:alert] = errors_for(@note).to_sentence
      render :show, status: :unprocessable_content
    end
  end

  def by_tag
    @tag = params[:id]
    @notes = Note.tagged_with(@tag).order(:title)
  end

  # Attachments are streamed through this action, not Active Storage's public
  # routes, so downloading a file requires a signed-in user.
  def download_file
    attachment = @note.note_attachments.find(params[:attachment_id])
    send_data attachment.file.download,
              filename: attachment.filename.to_s,
              type: attachment.content_type,
              disposition: "attachment"
  end

  def delete_file
    attachment = @note.note_attachments.find(params[:attachment_id])
    attachment.destroy
    redirect_to note_url(@note), notice: t("flash.file_deleted", filename: attachment.filename)
  end

  def destroy
    @note.destroy
    redirect_to notes_path, notice: t("flash.note_deleted", title: @note.title)
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  def note_params
    params.fetch(:note, {}).permit(:title, :description, :tag_list, :visited_on)
  end

  def finance_params
    params.expect(finance: %i[date amount comment])
  end

  def errors_for(note)
    note.errors.full_messages +
      note.finance_entries.flat_map { |entry| entry.errors.full_messages } +
      note.note_attachments.flat_map { |attachment| attachment.errors.full_messages }
  end
end
