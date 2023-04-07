require 'sidekiq/web'

Rails.application.routes.draw do
  get 'home/index'
  get '/get-suggestions', to: "home#get_suggestions"
  post '/get-suggestions', to: "home#get_suggestions"
  root "home#index"
  mount Sidekiq::Web => "/sidekiq"

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
