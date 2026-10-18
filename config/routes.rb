Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  resources :notes do
    member do
      get :by_tag
      get "files/:attachment_id", action: :download_file, as: :download_file
      get "files/:attachment_id/preview", action: :preview_file, as: :preview_file
      delete :delete_file
      post :share
      delete :share, action: :unshare
      get :history
      post "history/:version_id/restore", action: :restore, as: :restore_version
    end
  end

  # Public, read-only view of a shared note. The token is the secret.
  scope "s/:token", controller: :shared_notes do
    get "/", action: :show, as: :shared_note
    post "/", action: :unlock, as: :unlock_shared_note
    get "files/:attachment_id", action: :download_file, as: :shared_note_download
    get "files/:attachment_id/preview", action: :preview_file, as: :shared_note_preview
  end

  namespace :admin do
    root "dashboard#show"
    resources :users, except: %i[index show]
    resources :shares, only: :destroy
  end

  patch "preferences" => "preferences#update", as: :preferences

  # Health check for load balancers and container orchestrators.
  get "up" => "rails/health#show", as: :rails_health_check

  root "notes#index"
end
