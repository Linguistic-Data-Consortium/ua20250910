class ApplicationController < ActionController::Base
  include Authentication
  include SessionsHelper
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def respondj
    respond_to do |format|
      format.json do
        render json: yield
      end
    end
  end

  def allow(only)
    if only == :admin and admin?
      yield
    elsif only == :project_manager and project_manager?
      yield
    elsif only == :own and @instance.user_id == current_user.id
      yield
    elsif only == :any
      yield
    else
      { error: 'Permission denied.' }
    end
  end
  
  def index_all(model:, only:)
    respondj do
      allow(only) do
        model.sorted.all.map(&:attributes)
      end
    end
  end

  def index_allm(only:)
    index_all model: @model, only: only
  end

  def index_own(model:)
    respondj do
      model.sorted.where(user_id: current_user.id).map(&:attributes)
    end
  end

  def index_ownm
    index_own model: @model
  end

  def custom_attributes(a)
  end

  def show_users(model:, params:, users:, only:)
    respondj do
      allow(only) do
        m = model.find(params[:id])
        a = m.attributes
        a[users[0]] = users[1].call(m) if users
        custom_attributes a
        a
      end
    end
  end

  def show_usersm(params:, users:, only:)
    show_users model: @model, params: params, users: users, only: only
  end

  def createj(model:, params:, only:, own: false)
    respondj do
      allow(only) do
        instance = model.new params
        instance.user_id = current_user.id if own
        if instance.save
          instance.attributes
        else
          { error: instance.errors.full_messages }
        end
      end
    end
  end

  def createjm(params:, only:, own: false)
    createj model: @model, params: params, only: only, own: own
  end

  def updatej(model:, p:, params:, only:, own: false)
    respondj do
      instance = model.find(p[:id])
      @instance = instance
      allow(only) do
        if instance.update params
          instance.attributes
        else
          { error: instance.errors.full_messages }
        end
      end
    end
  end

  def updatejm(p:, params:, only:, own: false)
    updatej model: @model, p: p, params: params, only: only, own: own
  end

  def destroyj(model:, params:, only:, own: false)
    respondj do
      instance = model.find(params[:id])
      @instance = instance
      allow(only) do
        instance.destroy
        { deleted: "#{model} #{instance.name or instance.id} has been deleted." }
      end
    end
  end

  def destroyjm(params:, only:, own: false)
    destroyj model: @model, params: params, only: only, own: own
  end

  def reset_error_state
    @internal_server_error = false
  end

end
