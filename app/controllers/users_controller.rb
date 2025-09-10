class UsersController < ApplicationController

  # before_action :authenticate, :except => [ :new, :create, :mail_username, :check_username, :single ]
  # before_action :admin_user, :only => [ :destroy, :update_activated ]
  allow_unauthenticated_access only: %i[ new create ]

  include UsersHelper
  # include AwsHelper

  #action displays a list of all users
  def index
    User.all
    # if pii_manager?
    #   @title = "All users"
    #   respond_to do |format|
    #     format.html
    #     format.json do
    #       render json: User.all.map { |user|
    #         {
    #           id: helpers.link_to(user.id, user_path(user)),
    #           name: helpers.link_to(user.name, user_path(user)),
    #           edit: helpers.link_to("edit", edit_user_path(user)),
    #           reset: "#{user.reset_name ? 'yes' : 'no'} | #{helpers.link_to 'toggle', '#', :user_name => user.name, :class => 'toggle_name_reset'}",
    #           delete: helpers.link_to("delete", user, :method => :delete, :data => {:confirm => "This will delete the user: #{user.name}, are you sure you want to do this?"}, :title => "Delete #{user.name}", :id => "delete_#{user.id}")
    #         }
    #       }
    #     end
    #   end
    # else
    #   redirect_to(root_path)
    # end
  end

  #action displays a users profile page, which includes showing relevant information about the user
  def show
    # this puts everyone in Project Tutorial, Task Demo
    ProjectUser.where( project_id: 4, user_id: current_user.id ).first_or_create
    TaskUser.where( task_id: 21, user_id: current_user.id ).first_or_create
    @source = Source.new
    correct_user do
      @mode = $ua['mode']
      @single = @user.name == 'single'
      @banned_kits = [] #KitUser.includes(:kit).where( user_id: @user.id ).map { |x| x.kit }.compact # how did they get to be nil?
      @kits_available_by_task = Kit.where( state: :unassigned, user_id: [ @user.id, nil ] ).group(:task_id).count
      @kits_done_by_task = Kit.where( state: :done, user_id: @user.id ).group(:task_id).count
      @projects = @user.projects
      @task_users = @user.task_users.includes( task: [ :project, :workflow, :kit_type ] ).joins(:task).where("tasks.status = 'active'")
      @links = {}
      @project_owner = {}
      @project_admin = {}
      @user.project_users.each do |pu|
        @project_owner[pu.project_id] = pu.owner?
        @project_admin[pu.project_id] = pu.admin?
      end
      @task_users.each { |x| @links[x.id] = "/workflows/#{x.task.workflow_id}/work/#{x.id}" }

      #decides which partials(tabs) we should display for this user
      @tabs = get_tabs_for_user(@user)

      # gets tasks that user is qualified for by language and task_type (shows qualified or not)
      # only for projects that user is a member of
      @tasks_qualified_for_user = [] # list of task ids for which user is qualified
      # @task_types = TaskTypeUser.where(:user_id => @user.id, :status => "qualified").select(:task_type_id, :language_id)
      # @task_types.each do |task_type|
      #   Task.where(:language_id => task_type.language_id, :task_type_id => task_type.task_type_id, :project_id => @projects.select(:id)).each { |x| @tasks_qualified_for_user << x.id}
      # end

      #much trickery here to sort tasks available for user by deadline, assign priority in view
      @tasklist = {}
      @task_users.each do |x|
        if x.task.deadline
          @tasklist[x.task.id.to_s] = x.task.deadline
        end
      end
      @priority = @tasklist.sort_by {|key, value| value}


      # conditional in view needed for when this is 0

      @title = @user.name

      @task_users_count = TaskUser.where(task_id: @task_users.map(&:task_id)).group(:task_id).count
      if params[:pii] == 'true' and current_user?(@user) and pii_manager?
        current_user.start_pii_session
      end
      # redis = Redis.new(host: "redis", port: 6379)
      # redis.incr "page hits"
      # @page_hits = redis.get "page hits"
      tus = []
      @task_users.each do |tuser|
        tu = {}
        tus << tu
        project = tuser.project
        task = tuser.task
        tu[:project_id] = if tuser.admin? || @project_admin[project.id] || @project_owner[project.id] || @user.admin?
          project.id
        else
          0
        end
        tu[:project] = project.name
        tu[:task_id] =  if tuser.admin? || @project_admin[project.id] || @project_owner[project.id] || @user.admin?
          task.id
        else
          0
        end
        # tu[:task] = [ sprintf("%04d", task.id), task.name ].join ' '
        tu[:task] = task.name
        if task.workflow
          tu[:action] = get_action_link(task, tuser)
          tu[:state] = get_friendly_state_for_taskuser(tuser.state)
          tu[:done] = @kits_done_by_task[task.id].to_i
          if task.kit_type.constraints['free_choice'] or task.meta['free_upload']# and tuser.state == 'needs_kit'
            tu[:free] = true
            tu[:state] = tuser.state
            tu[:kit_uid] = tuser.kit_oid
            tu[:task_id] = task.id
            tu[:user_id] = tuser.user_id
            tu[:self] = tuser.user_id == current_user.id
            tu[:work_path] = "/workflows/#{tuser.id}/work/#{task.workflow_id}"
            tu[:bucket] = '' # task&.data_set&.name&.split&.first || ''
          end
        end
      end
      bucket_test = 0 #bucket_size("#{ENV.fetch('ACTIVE_STORAGE_BUCKET')}/demo")
      respond_to do |format|
        format.html
        format.json {
          render json: [ tus, @links, bucket_test ]
        }
      end
    end
  end

  #this action is for displaying the page where new users can sign up
  def new
    @user = User.new
  end

  #this action actually signs up new users
  def create
    @user = User.new(user_params)
    if @user.save
      if Rails.env.development?
        @user.activate
        start_new_session_for @user
      else
        if user_params[:name].match(/^TESTUSER/)
          @user.groups << Group.where(name: "TestUsers").first_or_create
        end
        @user.send_activation_email
        flash[:info] = 'Please check your email to activate your account.'
      end
      redirect_to root_url
    else
      render 'new'
    end
  end

  def single
    if Server.count == 0 and User.count == 0
      Server.create(name: 'single')
      user = login_anonymously
      user.update(name: 'single', admin: true, confirmed_at: Time.now + 100.years)
    else
      user = User.first
      if user.name == 'single' and user.admin
        log_in user
        remember user
      end
    end
    redirect_to root_url
  end

  private

  def user_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation, profile_attributes: [:year_of_birth, :gender, :cities, :languages_known])
  end

  #before_action that checks whether the current user and @user from the link match up, except for pii managers
  def correct_user
    @user = User.find(params[:id])
    if current_user?(@user) || pii?
      yield
    else
      flash[:error] = "you can't access other users' profiles"
      redirect_to root_path
    end
  end

end
