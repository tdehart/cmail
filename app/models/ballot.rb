class Ballot < ActiveRecord::Base
  #vote_check is called every time someone submits a vote
  #This method will determine if a ballot is finished based on different criteria
  #If a vote is finished, the appropriate tag or email is updated accordingly
  def self.vote_check(ballot)
    #Form a list of all the vote approvals (e.g., [true, true, false, nil])
    @votes = ballot.votes.map { |x| x.approval }.compact #list comprehension

    #exception requires unanimous decision
    if ballot.vote_type == 'exception'
      #condition 1: there's a false approval vote,
      if @votes.include?(false)
        #ballot did not pass
        ballot.update_attributes('over' => true, 'outcome' => 'failure')
        finished = true
        approved = false
        #condition 2: everyone has voted and they all approved (all true approvals)
      elsif @votes.size == ballot.votes.size and !@votes.include?(false)
        #ballot passed
        ballot.update_attributes('over' => true, 'outcome' => 'success')
        finished = true
        approved = true
        Email.find(ballot.content_id).update_attributes('sent' => true, 'sent_time' => Time.now)
      else
        finished = false
        approved = nil
      end

      if ballot.notification
        ballot.notification.update_attributes(:message => "Email Exception: #{@votes.count}/#{ballot.votes.count} votes", :finished => finished, :approved => approved)
      end

      #new tag votes require everyone to have voted (either false or true)
    elsif ballot.vote_type == 'new_tag'
      finished = false
      approved = nil
      @tag = Tag.find(ballot.content_id)
      #if voting is done
      if @votes.size == ballot.votes.size
        #find the tag then add everyone who voted 'yes' (all approval==true votes)
        finished = true
        approved = true
        ballot.votes.each do |v|
          if v.approval
            @tag.users << v.user
            @tag.users << User.find(ballot.author_id)
          end
        end
        #activate the tag
        @tag.update_attributes('approved' => true)
        ballot.update_attributes('over' => true, 'outcome' => 'success')
      end

      if ballot.notification
        ballot.notification.update_attributes(:message => "New Tag (#{@tag.name}): #{@votes.count}/#{ballot.votes.count} votes", :finished => finished, :approved => approved)
      end

      #adding and removing members requires unanimous voting
    elsif ballot.vote_type == 'add_tag_member' or ballot.vote_type == 'remove_tag_member'
      @tag = Tag.find(ballot.content_id)
      if ballot.vote_type == 'add_tag_member' then @message = "Add Member" else @message = "Remove Member" end
      finished = false
      approved = nil

      if @votes.include?(false)
        #ballot did not pass
        ballot.update_attributes('over' => true, 'outcome' => 'failure')
        finished = true
        approved = false
        @tag.update_attribute(:voteable, true)
      elsif @votes.size == ballot.votes.size and !@votes.include?(false)
        finished = true
        approved = true
        #ballot passed
        ballot.update_attributes('over' => true, 'outcome' => 'success')
        #find the tag and remove or add member depending on vote_type
        if ballot.vote_type == 'add_tag_member'
          @tag.users << User.find(ballot.member_id)
        elsif ballot.vote_type == 'remove_tag_member'
          @tag.users.delete(User.find(ballot.member_id))
        end
        @tag.update_attribute(:voteable, true)

      end

      if ballot.notification
        ballot.notification.update_attributes(:message => "#{@message} (#{@tag.name}): #{@votes.count}/#{ballot.votes.count} votes", :finished => finished, :approved => approved)
      end



    else
      #TODO: display some error here since vote_type wasn't set
    end
  end

  has_one :notification
  has_many :votes
  has_many :users, :through => :votes

  belongs_to :myballots, :polymorphic => true

end
