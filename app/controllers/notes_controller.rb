require 'open-uri'

class NotesController < ApplicationController

  def index
    @notes = Note.all
  end
  
  def show
    if params[:filename]
      @note = Note.find(params[:id])
      send_data @note.fetch_attachment(params[:filename]), :filename => params[:filename]
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
    params[:note][:updated_from] = current_user.username
    @note = Note.find(params[:id])
    tags = params[:note][:tags]
    params[:note][:tags] = tags.split(/\s+/) if params[:note][:tags]
    params[:note][:finance] = params[:finance] if params[:finance]
    
    @note.update_attributes(params[:note])
    
    respond_to do |wants|
      wants.html { redirect_to note_url(@note) }
    end
  end

  def by_tag
    @tag = params[:id]                         if params[:id]
    @notes = Note.by_tags :key => params[:id]  if params[:id]
  end

  def confirm_delete_file
    @filename = params[:filename]
    @note = Note.find(params[:id])
  end

  def delete_file
    @filename = params[:filename]
    @note = Note.find(params[:id])
    @note.delete_attachment(@filename)
    @note.save
    flash[:notice] = "file #{@filename} was deleted!"
    respond_to do |wants|
      wants.html { redirect_to note_url(@note) }
    end
  end
  
  def destroy
  end

end
