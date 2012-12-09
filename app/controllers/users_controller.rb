class UsersController < ApplicationController
  def index
    @myUsers = User.autocomplete(params[:term])

    respond_to do |format|
      format.html # index.html.erb
      format.json {
        @userNames = []
        @myUsers.each do |u|
          @userNames << u.email
        end
        render :json => @userNames
		  }
    end
  end
end
