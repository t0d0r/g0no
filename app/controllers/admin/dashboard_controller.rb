module Admin
  class DashboardController < BaseController
    def show
      @users = User.order(:created_at)
      @shared_notes = Note.shared.order(shared_at: :desc)
      @stats = {
        users: User.count,
        notes: Note.count,
        files: NoteAttachment.count,
        storage: ActiveStorage::Blob.sum(:byte_size),
        expenses: FinanceEntry.sum(:amount)
      }
    end
  end
end
