class NotesController < ApplicationController
  def index
    # @notes = Note.all
    # render :text => "text to render..."
  end
  
  def show
    @note = Note.find(params[:id])
  end
  
  def new
    @note = Note.new
  end
  
  def create
    note = Note.create(params[:note])
    note.save
  end
  
  def edit
    @note = Note.find(params[:id])
  end
  
  def update
    @note = Note.find(params[:id])
    @note = params[:note]
    
    respond_to do |wants|
      wants.html { redirect_to note_url(@note) }
    end
    # Can also catch RestClient::RequestFailed for a 412 conflict
  end
  
  def destroy
  end
end
