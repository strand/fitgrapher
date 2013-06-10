Fitgrapher::Application.routes.draw do
  root to: "activities#index"
  resources :activities, only: [:index]
end
