class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :get_notifications

  def get_notifications
      @notifications = Notification.joins(:ballot => :votes).where(:votes => {:user_id => current_user.id, :approval => true}) +
                       Notification.joins(:ballot => :votes).where(:votes => {:user_id => current_user.id, :approval => nil}) if user_signed_in?
  end
end
