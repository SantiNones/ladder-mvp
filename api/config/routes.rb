Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Namespaced under /api so a single deployed host can serve the built
  # React app from `public/` and the API from the same origin, with no
  # CORS needed. Dev's Vite proxy forwards /api unchanged to match.
  scope "/api" do
    get "me", to: "me#show"
    resources :snapshots, only: [:show]
    resources :people, only: [] do
      member { get :progress }
    end
  end
end
