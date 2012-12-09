class VotesController < ApplicationController
  before_filter :authenticate_user!
  def index
    @votes = current_user.votes

    respond_to do |format|
      format.html # index.html.erb
    end
  end


  def edit
    @vote = Tag.find(params[:id])
  end

  def update
    @vote = Vote.find(params[:id])

    @approval = params["approval_#{@vote.id}".to_sym]
    @approval = params[:approval] if @approval.nil?

    @vote.approval = @approval unless @approval.nil?
    @vote.save


    if @vote.update_attributes(params[:vote])
      Ballot.vote_check(@vote.ballot)
      respond_to do |format|
        format.html { redirect_to(emails_path, :notice => 'Vote successful') }
      end
    end
  end

  #This method is used for voting on multiple things at once (via checkboxes and JS buttons)
  def voteaction
    case params[:theaction]
    when 'yes'
      Vote.update_all(["approval=?", true], :id => params[:vote_ids])
    when 'no'
      Vote.update_all(["approval=?", false], :id => params[:vote_ids])
    end

    #Need to call vote_check for all of the ballots we're voting on
    @vote_ids = params[:vote_ids]
    @vote_ids.each do |vote_id|
      @vote = Vote.find(vote_id)
      Ballot.vote_check(@vote.ballot)
    end
    

    redirect_to ballots_path
  end

end

