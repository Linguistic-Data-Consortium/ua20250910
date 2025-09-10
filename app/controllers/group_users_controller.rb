class GroupUsersController < ApplicationController
  # before_action :authenticate

  def create
    respondj do
      allow(:admin) do
        group = Group.find params[:group_id]
        user = User.find params[:user_id]
        group.users << user
        { ok: "#{user.name} has been added to the group: #{group.name}" }
      end
    end
  end

  def destroy
    respondj do
      allow(:admin) do
        gu = GroupUser.find params[:id]
        group = gu.group
        group.delete_user gu.user
        { ok: "#{gu.user_name} has been removed from the group: #{group.name}" }
      end
    end
  end

end
