Toolkit::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # We can add the /api namespace later
  #namespace :api do
  #  resources :cloud_providers...
  #end

  # Temporary hack to prevent users from deleting their accounts
  delete 'users' => redirect('/')

  devise_for :users

  resources :clouds do
    resources :server_types, :storage_types, :database_types, :data_transfers
  end

  resources :additional_costs do
    post 'clone', :on => :member
  end

  resources :reports do
    post 'print', 'regenerate', :on => :member
  end

  resources :pattern_maps do
    put 'multi_update', :on => :collection
  end

  resources :patterns do
    post 'clone', :on => :member
    resources :rules do
      post 'clone', 'move_higher', 'move_lower', :on => :member
    end
  end

  resources :deployments do
    post 'clone', :on => :member
    resources :servers, :storages, :database_resources, :remote_nodes, :data_links, :additional_costs_deployments,
              :applications, :data_chunks do
      post 'clone', :on => :member
    end
  end

  # Leave these routes to be last, they are used by devise after signing in a user or updating the password
  get 'dashboard' => 'dashboard#index', :as => 'user_root'
  root :to => 'home#index'
  match '*url', :to => 'application#render_404'
end