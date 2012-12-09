class BallotsController < ApplicationController
  before_filter :authenticate_user!
  # GET /ballots
  # GET /ballots.xml
  def index
    
    @filter = params[:filter]

    if @filter.nil?
      @filter = 'pending'
    end

    if @filter == 'pending'
      #current_user.votes returns a relation which can be extended with the 'pending' scope and 'required' scope to filter only votes that are still pending and need the current_user to vote
      @votes = current_user.votes.pending.required.sort!{|a,b| b.created_at <=> a.created_at}
    elsif @filter == 'past'
      #current_user.votes returns a relation which can be extended with the 'past' scope to filter only votes that have been votes on
      @votes = current_user.votes.past.sort!{|a,b| b.created_at <=> a.created_at}
    else
      @votes = []
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ballots }
    end
  end

  # GET /ballots/1
  # GET /ballots/1.xml
  def show
    @ballot = Ballot.find(params[:id])

    if @ballot.vote_type == "exception"
      @email = Email.find(@ballot.content_id)
    end

    #give me the vote associated with this ballot (the current_user's vote)
    @myvote = @ballot.votes.map{|x| x if x.user_id == current_user.id}.compact[0]

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ballot }
    end
  end

  # GET /ballots/new
  # GET /ballots/new.xml
  def new
    @ballot = Ballot.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @ballot }
    end
  end

  # GET /ballots/1/edit
  def edit
    @ballot = Ballot.find(params[:id])
  end

  # POST /ballots
  # POST /ballots.xml
  def create
    @ballot = Ballot.new(params[:ballot])
    @ballot.update_attributes(:sent_time => Time.now)
    
    respond_to do |format|
      if @ballot.save
        format.html { redirect_to(@ballot, :notice => 'Ballot was successfully created.') }
        format.xml  { render :xml => @ballot, :status => :created, :location => @ballot }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @ballot.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ballots/1
  # PUT /ballots/1.xml
  def update
    @ballot = Ballot.find(params[:id])

    respond_to do |format|
      if @ballot.update_attributes(params[:ballot])
        format.html { redirect_to(@ballot, :notice => 'Ballot was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ballot.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ballots/1
  # DELETE /ballots/1.xml
  def destroy
    @ballot = Ballot.find(params[:id])
    @ballot.destroy

    respond_to do |format|
      format.html { redirect_to(ballots_url) }
      format.xml  { head :ok }
    end
  end
end
