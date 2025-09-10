Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  resource :browser, only: :show
  get 'browser/index', to: 'browsers#index'
  get 'browser/tabs', to: 'browsers#tabs'
  resource :recorder, only: :show
  

  get 'password_resets/new'

  get 'password_resets/edit'

  get :echo, to: 'pages#echo'
  root 'pages#home'
  get '/signup', to: 'users#new'
  post '/signup', to: 'users#create'
    # get '/login', to: 'sessions#new'
  # post '/login', to: 'sessions#create'
  # get '/confirmation', to: 'sessions#confirmation'
  # post '/confirm', to: 'sessions#confirm'
  # delete '/logout', to: 'sessions#destroy'
  # get '/logout2', to: 'sessions#destroy2'
  post '/users/single', to: 'users#single'
  resources :users
  # resources :sessions, only: [:create]
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]

  resources :kit_batches, only: [ :index, :show, :new, :create ]
  resources :user_defined_objects, as: :user_defined_objects

  resources :annotations
  get '/preann', to: 'annotations#preann'
  resources :reports

  post 'projects/respond_with_project', :to => 'projects#respond_with_project'
  get 'projects/:id/research_team', :to => 'projects#research_team', :as => 'projects_research_team'
  get 'projects/:id/users_not_in_project', to: 'projects#users_not_in_project', :as => 'users_not_in_project'
  get 'groups/:id/users_not_in', to: 'groups#users_not_in', :as => 'users_not_in'
  get 'projects/:id/project_users', to: 'projects#project_users', :as => 'project_project_users'
  get 'tasks/:id/task_users', to: 'tasks#task_users', :as => 'task_task_users'
  post 'tasks/respond_with_task', :to => 'tasks#respond_with_task'
  get 'tasks/recreate', :to => 'tasks#recreate'
  post 'data_sets/respond_with_dataset', :to => 'data_sets#respond_with_dataset'

  post 'add_user_to_project_and_task/:project_id/:task_id', :to => 'projects#add_user_to_project_and_task', :as => 'add_user_to_project_and_task'


  get 'class_defs_index2', to: "class_defs#index2"
  post 'editclassdef', to: "class_defs#editclassdef"
  resources :node_classes
  resources :nodes
  resources :trees
  resources :node_values
  resources :nde_values
  resources :constants
  resources :kit_batches, only: [ :index, :show, :new, :create ]
  resources :tasks, :except => [:new, :create]#if the task already exists, we can infer the project, for new/create it must be specified
  resources :projects, except: [ :new, :edit ] do
    resources :tasks, except: [ :new, :edit, :index ] do
      member do
        get :kit_creator
        post :file_upload
        post :kit_generation_preview
        post :generate_kits
        post :process_kits
        post :process_kits_preview
        get :reassign_kit
        get :kit_processor
        patch :reassign_many_kits
      end
    end
  end
  resources :task_users, :only => [ :show, :create, :update, :destroy ]
  resources :project_users
  post "/project_users/invite", to: "project_users#invite", as: "project_users_invite"
  post "/users/invite", to: "users#invite", as: "users_invite"
  get "/kits/all", to: 'kits#all'
  get "/kits_new", to: 'kits#kits_new'
  post "/create_kits_from_kits_tab", to: 'kits#create_kits_from_kits_tab'
  resource :kits do
    member do
      get ':id/unlock_tree', action: :unlock_tree, as: :unlock_tree
      get :get
      patch :change_kit_state
      post :get_time_spent
      get :get_time_spent
      post :change_time_spent
      get :change_time_spent
      post :get_message_from_journal
      get ':id/show', :action => :show, :as => :show
      get ':id/check', :action => :check, :as => :check
      patch ':id/update', :action => :update, :as => :update
      get 'task/:id', :action => :task, :as => :task
      post :set_kits_done
      get 'fix_floating_kits/:task/:new_state', :action => :fix_floating_kits, :as => :fix_floating_kits
      get :management
      get :trouble
      get ':id/undo', action: :undo
    end
  end
  post '/duration', to: 'kits#duration'
  post '/redactions', to: 'kits#redactions'

  resources :workflows do
    member do
      get 'read_only/:kit_id', to: 'task_users#read_only'
      # get 'quality_control/:kit_id/:task_id', :action => 'quality_control'
      get 'work/:workflow_id', to: 'task_users#get'
      # get 'work/:task_user_id/:value', :action => 'work'
      get 'set/:task_user_id/:value', :action => 'set'
      # get 'set_lock/:state', :action => 'set_lock'
    end
  end
  resources(:class_defs) do
    resources :node_classes do
      member do
        post :add_child
      end
    end
    member do
      get :css
      get :edit_css
      post :update_css
      get :tree_viewer
      get :preview
      get :release
      post :clone
      post :update_bootstrap_mode
      post :increment_version
      get 'set_lock/:state', :action => :set_lock
      get :tables
      get :create_tables
    end
  end

  resources :kit_types do
    get 'autocomplete', :on => :collection
    member do
      patch :update_name
      patch :update_type
      patch :update_meta
      patch :update_constraints
    end
  end
  resources :styles do
    member do
      post 'style_manager/:cid', :action => :style_manager
      post 'add_style/:cid', :action => :add_style
      post :add_property
    end
  end

  resources :data_sets do
    member do
      get 'get_urls'
    end
  end

  resource :sources do
    member do
      get :text
      get :audio
      get :audio_full
      post :get_text
      post :get_ner
      post :uget
      get :ugett
      post :uget_public
      get :get_upload
      get :get_download
      get :new
    end
  end

  resource :file_set do
    member do
      get :get_uploads
    end
  end

  resources :languages do
    get 'autocomplete', :on => :collection
  end

  resources :groups, except: [ :new, :edit ]
  resources :group_users, :only => [:create, :destroy]


  resources :invites
  resources :features, except: [ :new, :edit ]

  get '/bucket', to: 'data_sets#bucket'
  post '/token', to: 'cognito_token#get_credentials'
  post '/rev', to: "rev#rev"
  
  resources :actions, only: [ :create ]
  resources :xamespaces, except: [ :new, :edit ]

  resources :jwts, only: [ :create, :index ]

end
