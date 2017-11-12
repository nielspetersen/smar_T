Rails.application.routes.draw do
  root 'welcome#index'

  get 'about/index'

  resources :customers

  resources :vehicles

  resources :tours

  get 'tours/:id/print' => 'tours#print', as: 'print_tour'
  get 'tours/:id/start' => 'tours#start', as: 'start_tour'
  get 'tours/:id/complete' => 'tours#complete', as: 'complete_tour'
  post 'tours/:id/finish' => 'tours#finish', as: 'finish_tour'

  resources :restrictions

  resources :orders

  resources :order_tours

  resources :drivers

  resources :depots

  resources :companies

  resources :registered_users

  resources :user_forms

  get'order_import/file', as:  'file_order_import'
  post 'order_import/confirm', as: 'confirm_order_import'
  post 'order_import/complete', as: 'complete_order_import'

  get 'developer/index'
  post 'developer/reset_database'

  post "tours/positions/update" => "order_tours#update_positions"

  devise_for :users, controllers: { registrations: "users/registrations", passwords: "users/passwords" }, skip: [:sessions, :registrations]
  devise_for :users, controllers: { sessions: "sessions" }

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  #->Prelang (user_login:devise/stylized_paths)
end
