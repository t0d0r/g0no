require 'open-uri'

class NotesController < ApplicationController

  def index
    @notes = Note.all
  end
  
  def show
    if params[:filename]
      @note = Note.find(params[:id])
      send_data @note.fetch_attachment(params[:filename]), :filename => @note.real_filename(params[:filename])
    else
      @note = Note.find(params[:id])
    end
  end
  
  def new
    @note = Note.new
  end
  
  def create
    params[:note][:author] = current_user.username || current_user.email
    if Note.create params[:note]
      flash[:success] = "Success !"
    else
      flash[:error] = "Fail !"
    end
    redirect_to notes_path
  end
  
  def edit
    MarkItUp.skin = "simple"
    @note = Note.find(params[:id])
  end
  
  def update
    params[:note][:updated_from] = current_user.username || current_user.email
    @note = Note.find(params[:id])
    tags = params[:note][:tags]
    params[:note][:tags] = tags.split(/\s+/) if params[:note][:tags]
    if params[:note][:attachments]
      params[:note][:attachments].each { |attachment|
        @note.attach_comments_to_filename(attachment.original_filename, params[:note][:attachment_comment])
      }
    end
    if params[:finance]
      params[:finance][:author] = current_user.username || current_user.email
      @note.add_finance = params[:finance]
    end
    @note.update_attributes(params[:note])
    
    respond_to do |wants|
      wants.html { redirect_to note_url(@note) }
    end
  end

  def by_tag
    @tag = params[:id]                         if params[:id]
    @notes = Note.by_tags :key => params[:id]  if params[:id]
  end

  def delete_file
    filename = params[:filename]
    begin
      @note = Note.find(params[:id])
      flash[:notice] = "file #{@note.real_filename(filename)} was deleted!"
      @note.delete_attachment(filename)
      @note.save
    rescue 
      flash[:notice] = "file #{@note.real_filename(filename)} is still here!"
    end

    respond_to do |wants|
      wants.html { redirect_to note_url(@note) }
    end
  end
  
  def destroy
    @note = Note.find(params[:id])
    if @note.destroy
      flash[:notice] = "Документ със заглавие '#{@note.title}' беше изтрит успешно"
    end
    redirect_to :action => "index"
  end

  private

  def attach_comments_to_filenames(note, filename)
    comment = params[:note][:attachment_comment]
    key = note.attachment_hash(filename)
    if note.attachments_nfo.has_key?(key)
      note.attachments_nfo[key].merge( { :comment => comment } )
    else
      note.attachments_nfo[key] =  { :comment => comment } 
    end
    note
  end


end
