class EmailsController < ApplicationController
  before_filter :authenticate_user!
  uses_tiny_mce :only => [:new]
  
  # GET /emails
  # GET /emails.xml
  def index
    #votes will be displayed in the Inbox so we need this available here
    @votes = current_user.votes.map{|x| x if x.approval == nil}.compact

    #The filter is used to allow users to switch between incoming email, sent email, etc
    @filter = params[:filter]
    
    if @filter.nil? 
      @filter = "inbox"
    end
    @total_email = current_user.emails.sent_emails.count
    if @filter == 'inbox'
      #current_user.emails returns a relation which can be extended with the 'sent' scope to filter only emails that have been sent
      @email = current_user.emails.sent_emails.not_trash_emails.sort!{|a,b| b.sent_time <=> a.sent_time}
    elsif @filter == 'sent'
      #Find all emails where author_id = current_user.id
      @email = Email.where("author_id = ?", current_user.id).not_trash_emails.sent_emails.sort!{|a,b| b.sent_time <=> a.sent_time}
    elsif @filter == 'drafts'
      @email = current_user.emails.draft_emails.not_trash_emails.sort!{|a,b| b.sent_time <=> a.sent_time}
    elsif @filter == 'trash'
      #find all emails that have been sent and all emails received then paginate them!
      @email = (current_user.emails.trash_emails | Email.where("author_id = ?", current_user.id).trash_emails).sort!{|a,b| b.sent_time <=> a.sent_time}
    else
      @email = []
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @emails }
    end
  end

  # GET /emails/1
  # GET /emails/1.xml
  def show
    @email = Email.find(params[:id])
    @tags = @email.tags

    @email.mark_read = true
    @email.save
    
    #Find the author of the email by searching the User model
    @author = User.find_by_id(@email.author_id)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @email }
    end
  end

  # GET /emails/new
  # GET /emails/new.xml
  def new
    @email = Email.new
    @response = params[:response]

    #If reply/forward
    if !@response.nil?
      if !params[:old_email].nil?
        @old_email = Email.find(params[:old_email])
        @old_email_author = User.find(@old_email.author_id)
        if !@old_email.tags.nil?
          @old_email_tags = @old_email.tags
        end
      end
      if @response == "reply"
        @email.title = "Re: " + @old_email.title
        @recipients = @old_email_author.email + ", "
      elsif @response == "reply_all"
        @email.title = "Re: " + @old_email.title
        @new_recipients = [@old_email_author] + @old_email.users - [current_user]
        @recipients = @new_recipients.map{|x| x.email}.compact.join(", ") + ", "
      elsif @response == "forward"
        @email.title = "Fwd: " + @old_email.title
        @body = "\n\n\n\n---------- Forwarded message ----------\n" +
                "From: " + @old_email_author.name + " <" + @old_email_author.email + ">\n" +
                "Date: " + @old_email.created_at.strftime("%b %e %Y at %I:%M%p ") +
                "\nSubject: " + @old_email.title +
                "\nTo: " + @old_email.users.map{|x| x.email}.compact.join(",") + "\n\n\n" +
                @old_email.body
      elsif @response == "tag_email"
        @from_tag = Tag.find(params[:tag])
        @tag_members = @from_tag.users - [current_user]
        @recipients = @tag_members.map{|x| x.email}.compact.join(", ") + ", "
      end
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @email }
    end
  end

  # GET /emails/1/edit
  def edit
    @email = Email.find(params[:id])
  end

  # POST /emails
  # POST /emails.xml
  def create
    @email = Email.new(params[:email])

    #sometimes we use text_area_tag so we need to manually populate body field
    @email.body = params[:email_body] if @email.body.nil?

    @email.sent_time = Time.now
    
    ### We need to set up the error checking variables ###
    @invalid_recipients = []
    @invalid_tags = []
    @sending = true

    ### Set the email's author ###
    @email.author_id = current_user.id

    #Separate recipients by comma and semicolons then make sure each recipient exists in the system
    #@recipients = params[:recipients].delete(" ").split(/[\,\;]/)
    @recipients = params[:recipients].split(/[,;]\s?/)
    ### Associate the recipients (Users) with the Email model###
    @recipients.each do |email|
      @user = User.find_by_email(email.strip)
      if @user.nil? #one of the users in the list does not exist in the system
        @invalid_recipients << email
      else
        @email.users << @user
      end
    end

    ### Associate the Tags with the Email model ###
    @tags = params[:tags].split(/[,;]\s?/)
    @tags_approved = true
    @tags.each do |tag|
      @tag = Tag.find_by_name(tag.strip)
      if !@tag.users.include?(current_user)
        flash[:notice] = "You are not a member of the " + @tag.to_s + " tag."
        @sending = false
      end
      if @tag.nil? or @tag.approved == false #one of the tags in the list does not exist in the system or it's not yet approved
        @invalid_tags << tag
      else
        @email.tags << @tag
      end
    end

    ### [COPS] Determine if there will be an exception ###
    #if there are no tags, don't do COPS validation
    if @email.tags.empty?
      @verified = true
    else
      #find the authorized recipients by taking the intersection of all the tags' users (COPS model)
      @authorized_recipients = Tag.intersection(@email)
      @unauthorized_recipients = []
      @verified = true

      #this is where we check if the email's recipients match the authorized recipients
      @email.users.each do |user|
        if !@authorized_recipients.include?(user)
          @verified = false
          @unauthorized_recipients << user
        end
      end
    end
    
    #[COPS] if there was an exception then we must let the users vote before "sending" this email
    if @verified then
      @email.sent = true
    end
    
    
    respond_to do |format|
      if @invalid_recipients.size > 0 or @invalid_tags.size > 0
        format.html{render 'errors'}
      elsif !@sending
        format.html { render :action => "new" }
      else
        if @email.save
          if @verified
            @email.update_attributes(:sent => true)
            format.html { redirect_to(emails_path, :notice => 'Email was successfully sent.') }
          else
            @email.update_attributes(:sent => false)
            format.html{render 'exception'}
          end
        else
          format.html { render :action => "new", :notice => "Email was not successfully sent" }
          format.xml  { render :xml => @email.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def exception
    #Can't pass objects around so we need to rebuild them from strings
    @email = Email.find(params[:email])
    #Take every email address (split by spaces) and find the user associated with it, put it in an array
    @authorized_recipients = params[:authorized].split(" ").map{|x| User.find_by_email(x)}.compact

    #Create a new Ballot for this email which will distribute a vote to every authorized recipient
    @exception_ballot = Ballot.new('content_id' => @email.id, 'over' => false, 'vote_type' => 'exception', 'users' => @authorized_recipients, 'author_id' => current_user.id)
    @exception_ballot.save
    @exception_ballot.create_notification(:message => "Email Exception: 1/#{@authorized_recipients.count} votes", :finished => false)
    #Set author ballot to true since they're the creator of the vote
    @author_vote = @exception_ballot.votes.find_by_user_id(current_user.id)
    @author_vote.approval = true
    @author_vote.save
    Ballot.vote_check(@exception_ballot)
    @email.ballots << @exception_ballot
    @email.save
    redirect_to(emails_path, :notice => 'Voting in progress.')
    
  end

  # PUT /emails/1
  # PUT /emails/1.xml
  def update
    @email = Email.find(params[:id])

    @email.trash = params[:delete]
    @email.mark_read = params[:mark_read]

    @email.save

    #redirect_to emails_path

    #    respond_to do |format|
    #      if @email.update_attributes(params[:email])
    #        format.html { redirect_to(@email, :notice => 'Email was successfully updated.') }
    #        format.xml  { head :ok }
    #      else
    #        format.html { render :action => "edit" }
    #        format.xml  { render :xml => @email.errors, :status => :unprocessable_entity }
    #      end
    #    end
  end

  # DELETE /emails/1
  # DELETE /emails/1.xml
  def destroy
    @email = Email.find(params[:id])
    @email.destroy

    respond_to do |format|
      format.html { redirect_to(emails_url) }
      format.xml  { head :ok }
    end
  end

  #Mark selected emails as trash emails
  def emailaction
    case params[:theaction]
    when 'trash'
      Email.update_all(["trash=?", true], :id => params[:email_ids])
    when 'read'
      Email.update_all(["mark_read=?", true], :id => params[:email_ids])
    end
    
    redirect_to emails_path
  end
  
end