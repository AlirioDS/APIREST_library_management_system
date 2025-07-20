Rails.application.routes.draw do
  # Web interface routes (if needed later)
  resource :session
  resources :passwords, param: :token
  
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      scope :auth do
        post :login, to: 'authentication#login'
        post :register, to: 'authentication#register'
        post :refresh, to: 'authentication#refresh'
        delete :logout, to: 'authentication#logout'
        get :me, to: 'authentication#me'
      end
      
      # User management routes
      resources :users do
        member do
          patch :change_role
          get :borrowings, to: 'borrowings#user_borrowings'
        end
      end
      
      # Book management routes
      resources :books do
        member do
          patch :manage_status
          post :borrow, to: 'borrowings#borrow_book'
          get :borrowings, to: 'borrowings#book_borrowings'
        end
        collection do
          get :search
        end
      end
      
      # Borrowing management routes
      resources :borrowings, only: [:index, :show] do
        member do
          patch :return, to: 'borrowings#return_book'
        end
      end
      
      # Direct borrowing action routes
      post 'borrowings/borrow_book', to: 'borrowings#borrow_book'
      get 'borrowings/user_borrowings', to: 'borrowings#user_borrowings'
      get 'borrowings/book_borrowings', to: 'borrowings#book_borrowings'
      
      # Dashboard routes
      scope :dashboard do
        get :librarian, to: 'dashboard#librarian'
        get :member, to: 'dashboard#member'
      end
    end
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
