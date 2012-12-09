class NotificationsController < ApplicationController
  def index
    @notifications = Notification.joins(:ballot => :votes).where(:votes => {:user_id => current_user.id, :approval => true}) +
        Notification.joins(:ballot => :votes).where(:votes => {:user_id => current_user.id, :approval => nil}) if user_signed_in?

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
  end

  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy

    respond_to do |format|
      format.js { render :nothing => true }
    end
  end

end
