# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Heroku's resource provisioning and deprovisioning endpoints
  namespace :heroku do
    resources :resources, only: %i[create destroy],
                          constraints: ->(req) { req.headers["Accept"] == Heroku::MimeType::ADDON_PARTNER_API }
    match "*path" => "errors#not_found", :via => :all
  end

  namespace :sso do
    post :login, to: "sessions#create", as: :login
    delete :logout, to: "sessions#destroy", as: :logout
  end

  namespace :logplex do
    resources :log_frames, only: :create,
                           constraints: ->(req) { req.headers["Content-Type"] == "application/logplex-1" }
    post "log_frames", to: "errors#unsupported_media_type"
    match "*path" => "errors#not_found", :via => :all
  end

  root to: "dashboards#show", as: :dashboard
end
