# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
User.delete_all
Tag.delete_all
Ballot.delete_all
Vote.delete_all
Email.delete_all
Notification.delete_all

#Create users
[["bob@company.com", "Bob Tilford"], ["tom@company.com", "Tom Martin"], ["dan@company.com","Dan McMillian"],
  ["john@company.com", "John Pinnel"], ["sherley@company.com", "Sherley Montano"], ["mary@company.com","Mary Byford"],
  ["david@company.com", "David Jones"], ["kristen@company.com", "Kristen Scott"], ["susan@company.com", "Susan Williams"],
  ["jake@company.com", "Jake Williams"], ["jessie@company.com", "Jessie Smith"], ["sarah@company.com", "Sarah Thompson"], 
  ["brian@company.com", "Brian Caldwell"], ["allison@company.com", "Allison Watts"], ["michael@company.com", "Michael Brown"]].each do |u|
	if (User.where("email = ?", u[0]).empty?)
		User.new( :email => u[0], :name => u[1], :password => '123123', :password_confirmation => '123123' ).save!
	end
end
#["Human Resources", ["sarah@company.com", "jessie@company.com", "susan@company.com", "mary@company.com", "sherley@company.com", "david@company.com", "dan@company.com", "john@company.com"], "A community tag for all Human Resources correspondence"]
#Create tags and assign users
[["Corporate", ["michael@company.com","brian@company.com", "sarah@company.com", "bob@company.com", "tom@company.com", "dan@company.com", "john@company.com", "sherley@company.com", "mary@company.com", "david@company.com", "kristen@company.com", "susan@company.com", "jake@company.com", "jessie@company.com"], "Corporate-wide community tag"],
  ["Managers", ["jake@company.com", "jessie@company.com", "david@company.com", "sherley@company.com"], "Exclusive community tag used for managers"]].each do |tag|
  @users = tag[1].map{|u| User.find_by_email(u)}.compact
  Tag.new(:name => tag[0], :users => @users, :description => tag[2], :approved => true).save!
end

@emails = [
  ["Hiring Policies", "Hi Jessie,<p>Could you please send me a copy of the Hiring Policies section from the company handbook?</p>Thanks,<br />Tom", "tom@company.com", "", ["jessie@company.com"]],
  ["2nd Quarterly Report 2012", "Greetings,<p>The 2012 2nd Quarterly Report is in. Please see attached for details.</p>Best,<br />David", "david@company.com", "Managers", ["jake@company.com", "jessie@company.com", "david@company.com", "sherley@company.com"]],
  ["Great job", "Jessie,<p>These hiring reports look great. Keep up the good work!</p>-Sherley", "sherley@company.com", "Managers", ["jessie@company.com"]],
  ["Please schedule training for new software developers", "<p>Four new developers were hired last week. Please see that their orientation and training is scheduled.</p> Regards,<br />David", "jake@company.com", "Managers", ["jessie@company.com"]],
  ["Thanks again", "Hi Jessie,<p>I just wanted to thank you again for recommending the IP training program, it has already begun to help a lot!</p>Cheers,<br />Bob", "bob@company.com", "", ["jessie@company.com"]],
  ["who should I contact from the R&D department about this issue?", "Jessie,<p>Could you send me a contact from R&D that would know the most about our User Feedback of last year's release?</p>Regards,<br />John", "john@company.com", "", ["jessie@company.com"]],
  ["Hiring increase", "Greetings,<p>We've had a good fiscal year and aim to increase hiring over the next 6 months. Please be on the lookout for new talent and keep up the good work!</p>Regards,<br />David", "david@company.com", "Corporate", ["bob@company.com", "tom@company.com", "dan@company.com", "john@company.com", "sherley@company.com", "mary@company.com", "david@company.com", "kristen@company.com", "susan@company.com", "jake@company.com", "jessie@company.com"]],
  ["quick question", "how many people did we hire last month in the Risk Prevention department?", "kristen@company.com", "", ["jessie@company.com"]],
  ["Short vacation", "<p>I'll be out of the office from 02-15 to 02-17 to visit family but I might be able to skype into any meetings if needed.</p>-Susan", "susan@company.com", "", ["jessie@company.com", "susan@company.com", "mary@company.com", "sherley@company.com", "david@company.com", "dan@company.com", "john@company.com"]]
]
@emails.each do |e|
  @author_id = User.find_by_email(e[2]).id
  @tag = nil
  if !e[3].empty?
    @tag = Tag.find_by_name(e[3])
  end
  @recipients = e[4].map{|u| User.find_by_email(u)}.compact
  if !@tag.nil?
    @email = Email.new(:title => e[0], :body => e[1], :author_id => @author_id, :users => @recipients, :sent => true)
    @email.tags << @tag
  else
    @email = Email.new(:title => e[0], :body => e[1], :author_id => @author_id, :users => @recipients, :sent => true)
  end

  @email.mark_read = true
  
  @recipients.each do |r|
    @email.users << r
  end
  @email.save!
  @email.update_attribute :sent_time, rand(1.week).ago
end

puts 'Seeding finished'
