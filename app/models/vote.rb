class Vote < ActiveRecord::Base
  #we can use this to return just email that have been sent
  #scope :pending, :conditions => {:approval => nil}
  scope :required, where(:approval => nil)
  scope :pending, joins(:ballot).where('ballots.over = ?', false)
  scope :past, where('approval = ? or approval = ?', true, false)
  
  belongs_to :ballot
  belongs_to :user
end
