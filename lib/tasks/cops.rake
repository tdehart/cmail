#Makes an email given a list e
def makeEmail(e)
  @author_id = User.find_by_email(e[2]).id
  if !e[3].empty?
    @tag = Tag.find_by_name(e[3])
  end
  @recipients = e[4].map{|u| User.find_by_email(u)}.compact
  if !@tag.nil?
    newEmail = Email.new(:title => e[0], :body => e[1], :author_id => @author_id, :users => @recipients, :sent => true)
    newEmail.tags << @tag
  else
    newEmail = Email.new(:title => e[0], :body => e[1], :author_id => @author_id, :users => @recipients, :sent => true)
  end

  @recipients.each do |r|
    newEmail.users << r
  end
  
  return newEmail
end

#Sets all vote approvals to true for all ballots of Human Resources
task :HRVoting => :environment do
  @ballots = Tag.find_by_name("Human Resources").ballots
  @ballots.each do |b|
    b.votes.each do |v|
      v.update_attribute(:approval, true)
    end
    Ballot.vote_check(b)
  end
  
  puts 'HRVoting finished'
end

#Sends Tutorial Part 4 response to Jessie (the user)
task :maryEmail => :environment do
  @mary = User.find_by_email("mary@company.com")
  @jessie = User.find_by_email("jessie@company.com")
  @oldEmail = @mary.emails[-1]
  @email = [
    "Re: "+@oldEmail.title,
    "<p>Great news, thanks for the update!</p> -Mary",
    "mary@company.com",
    "",
    ["jessie@company.com"]]

  @newEmail = makeEmail(@email)
  @newEmail.update_attribute :sent_time, Time.now.in_time_zone("Eastern Time (US & Canada)")
  @newEmail.save

  puts "Mary's email sent!"
end

#Creates the complaint email
task :complaintEmail => :environment do
  @email = [
    "Filing formal complaint",
    "Jessie, <p>I'd like to formally file a complaint against my department manager, Bob Tilford. His absence durings meetings and general lack of enthusian for our project is starting to affect the department's morale. Please let know when we can meet in person to discuss this matter further. </p> Thanks,<br />Kristen ",
    "kristen@company.com",
    "",
    ["jessie@company.com"]]

  @newEmail = makeEmail(@email)
  @newEmail.update_attribute :sent_time, Time.now.in_time_zone("Eastern Time (US & Canada)")
  @newEmail.save

  puts "Successfully made 'Complaint Email'"
end



#For fixing HR if needed - just creates Human Resources and adds all members from tutorial
task :fixHR => :environment do
  @tag = Tag.find_by_name("Human Resources")
  @users = ["jessie@company.com", "mary@company.com", "john@company.com", "allison@company.com", "sarah@company.com"].map{|u| User.find_by_email(u)}.compact
  if @tag.nil?
    Tag.new(:name => "Human Resources", :description => "A tag for the Human Resources department", :approved => true)
  end
  @tag.users << @users
  @tag.save
end
  
task :HREmails => :environment do
  @emails = [
    ["office party 02-24 please RSVP!!", "Hi all,<p>The HR office party will take place on Friday, February 24. Please let me know ASAP if you can make it.</p>-Mary B.", "mary@company.com", "Human Resources", ["jessie@company.com", "john@company.com", "allison@company.com", "sarah@company.com"]],
    ["Need help with this issue..", "Hey Jessie,<p>I was just going over a complaint received from an employee in the R&D dept. and was wondering if you could take a look. I left a copy on your desk with a purple sticky note attached.</p>Thanks,<br />John", "john@company.com", "Human Resources", ["jessie@company.com"]],
    ["New list of potential hirees", "Hi all,<p>Attached is a list of the potential hirees for the HR department. Please look them over before the meeting tomorrow.</p>Thanks,<br />Mary", "mary@company.com", "Human Resources", ["jessie@company.com", "john@company.com", "allison@company.com", "sarah@company.com"]],
  ]

  @emails.each do |e|
    @newEmail = makeEmail(e)
    @newEmail.update_attribute :mark_read, true
    @newEmail.update_attribute :sent_time, rand(1.week).ago
  end

  puts "HR emails sent"
end

#Creates the remove member email
task :removeMemberEmail => :environment do
  #Write email to user telling them to remove Michael Brown (michael@company.com)
  @email = [
    "Corporate tag cleanup",
    "Hi Jessie, <p>Michael Brown retired last month but I just noticed that he's still a member of the 'Corporate' tag. Please remove him from the tag when get a chance. </p> Thanks,<br />Kristen ",
    "kristen@company.com",
    "",
    ["jessie@company.com"]]

  @newEmail = makeEmail(@email)
  @newEmail.update_attribute :sent_time, Time.now.in_time_zone("Eastern Time (US & Canada)")
  @newEmail.save

  puts "Successfully made 'Remove Member Email'"
end