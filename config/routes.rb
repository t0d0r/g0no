Rails.application.routes.draw do
  devise_for :users

  resources :notes do
    member do
      get :by_tag
      get "files/:attachment_id", action: :download_file, as: :download_file
      delete :delete_file
    end
  end

  # Health check for load balancers and container orchestrators.
  get "up" => "rails/health#show", as: :rails_health_check

  root "notes#index"
end
