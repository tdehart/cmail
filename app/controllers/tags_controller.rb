class TagsController < ApplicationController
  before_filter :authenticate_user!
  
  # GET /tags
  # GET /tags.xml
  def index
    @filter = params[:filter]

    if @filter.nil?
      @filter = "current"
    end

    if @filter == "current"
      @tags = current_user.tags.current_tags
    elsif @filter == "archived"
      @tags = current_user.tags.archived_tags
    else
      @tags = []
    end

    @myTags = current_user.tags.autocomplete(params[:term])
    
    respond_to do |format|
      format.html # index.html.erb
      format.json {
        @tagNames = []
        @myTags.each do |t|
          @tagNames << t.name
        end
        render :json => @tagNames
		  }
    end
  end

  # GET /tags/1
  # GET /tags/1.xml
  def show
    @tag = Tag.find(params[:id])


    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tag }
    end
  end

  # GET /tags/new
  # GET /tags/new.xml
  def new
    @tag = Tag.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @tag = Tag.find(params[:id])
  end

  # POST /tags
  # POST /tags.xml
  def create
    @tag = Tag.new(params[:tag])
    @tag.name.strip!

    #invalid_members and invalid_tags used for COPS error reporting
    @invalid_members = []
    @invalid_tags = []
    
    #'members' will hold all of the potential members for this tag
    @members = [current_user]

    #if user entered some email addresses add them to @members
    if !params[:members].nil?
      @member_emails = params[:members].split(/[,;]\s?/)
      @member_emails.each do |member|
        @member = User.find_by_email(member.strip)
        if @member.nil?
          @invalid_members << member
        else
          @members << @member
        end
      end
    end

    #if user entered some tags add each tag's users to @members
    if !params[:other_tags].nil?
      @tags = params[:other_tags].split(/[,;]\s?/)
      @tags.each do |tag|
        @other_tag = Tag.find_by_name(tag)
        if @other_tag.nil?
          @invalid_tags << tag
        else
          @members = @members | @other_tag.users
        end
      end
    end

    @tag.approved = false

    respond_to do |format|
      if (@invalid_members.size > 0 or @invalid_tags.size > 0) or (@members.empty?)
        format.html{render 'tags/new/errors', :locals => {:invalid_members => @invalid_members, :invalid_tags => @invalid_tags, :members => @members}}
      else
        if @tag.save
          #Create a new ballot for this tag's creation
          @newtag_ballot = Ballot.new('content_id' => @tag.id, 'over' => false, 'vote_type' => 'new_tag', 'users' => @members, 'author_id' => current_user.id)
          @newtag_ballot.save
          @newtag_ballot.create_notification(:message => "New Tag (#{@tag.name}) 1/#{@members.count} votes", :finished => false)
          @tag.ballots << @newtag_ballot
          #Set author ballot to true since they're the creator of the vote
          @author_vote = @newtag_ballot.votes.find_by_user_id(current_user.id)
          @author_vote.approval = true
          @author_vote.save
          @tag.save
          format.html { redirect_to(tags_path, :notice => "You have created a tag and it is now in the voting process") }
          format.xml  { render :xml => @tag, :status => :created, :location => @tag }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.xml
  def update
    @tag = Tag.find(params[:id])
    @edit_type = params[:edit_type]
    if @edit_type == 'add'
      @person = User.find_by_email(params[:add_person])
    elsif @edit_type == 'remove'
      @person = User.find_by_email(params[:remove_person])
    end
    #This is needed for the jQuery .submit() call
    @archive = params["archive_#{@tag.id}".to_sym]
    @tag.archived = @archive unless @archive.nil?
    @tag.save

    #Don't let more than one vote per member occur
    if @edit_type == 'add' or @edit_type == 'remove'
      @tag.ballots.each do |b|
        if b.member_id == @person.id and b.over == false
          redirect_to(tag_path(@tag), :notice => "There is already a vote in progress for " + @person.to_s)
          return
        end
      end
    end

    if @edit_type == 'add'
      if @person == current_user
        redirect_to(tag_path(@tag), :notice => "You can't add/remove yourself from the tag!")
        return
      elsif @tag.users.include?(@person)
        redirect_to(tag_path(@tag), :notice => params[:add_person] + " is already a member of this tag.")
        return
      elsif @person.nil?
        redirect_to(tag_path(@tag), :notice => params[:add_person] + " does not exist.")
        return
      end
      #create a ballot for this member add; create votes for everyone including the person being invited
      @edittag_ballot = Ballot.new('content_id' => @tag.id, 'over' => false,
        'vote_type' => 'add_tag_member', 'users' => @tag.users + [@person],
        'member_id' => @person.id, 'author_id' => current_user.id)
      @edittag_ballot.save
      @edittag_ballot.create_notification(:message => "Add Member (#{@tag.name}) 1/#{@tag.users.count+1} votes", :finished => false)
      @tag.ballots << @edittag_ballot
      @tag.save
    elsif @edit_type == 'remove'
      if @person == current_user
        redirect_to(tag_path(@tag), :notice => "You can't add/remove yourself from the tag!")
        return
      elsif @tag.voteable == false
        redirect_to(tag_path(@tag), :notice => "A remove member vote is currently in progress and must be resolved before starting another remove member vote.")
        return
      elsif @person.nil?
        redirect_to(tag_path(@tag), :notice => params[:remove_person] + " does not exist.")
        return
      elsif !@tag.users.include?(@person)
        redirect_to(tag_path(@tag), :notice => params[:remove_person] + " is not a member of this tag.")
        return
      end
      #create a ballot for this member removal; create votes for everyone but the current_user and the person we're removing
      @edittag_ballot = Ballot.new('content_id' => @tag.id, 'over' => false,
        'vote_type' => 'remove_tag_member', 'users' => @tag.users - [@person],
        'member_id' => @person.id, 'author_id' => current_user.id)
      @edittag_ballot.save
      @edittag_ballot.create_notification(:message => "Remove Member (#{@tag.name}) 1/#{@tag.users.count-1} votes", :finished => false)
      @tag.voteable = false
      @tag.ballots << @edittag_ballot
      @tag.save
    else
      #edit_type not found
    end

    if @edit_type == 'add' or @edit_type == 'remove'
      #The person starting the vote will have their vote set to True automatically
      @current_user_vote = Vote.find_by_user_id_and_ballot_id(current_user.id, @edittag_ballot.id)
      @current_user_vote.approval = true
      @current_user_vote.save
    end

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        format.html { redirect_to(@tag, :notice => 'Tag was successfully updated. If you added or removed a member, a vote is now in progress.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.xml
  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to(tags_url) }
      format.xml  { head :ok }
    end
  end

  def tagaction
    case params[:theaction]
    when 'archive'
      Tag.update_all(["archived=?", true], :id => params[:tag_ids])
    when 'restore'
      Tag.update_all(["archived=?", false], :id => params[:tag_ids])
    end
    redirect_to tags_path
  end

end
