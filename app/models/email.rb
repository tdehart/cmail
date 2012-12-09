class Email < ActiveRecord::Base
  attr_accessible :title, :body, :sent, :author_id

  validates :title, :presence => true
  validates :users, :presence => true

  scope :sent_emails, :conditions => {:sent => true}
  scope :not_trash_emails, :conditions => {:trash => false}
  scope :not_draft_emails, :conditions => {:draft => false}
  scope :trash_emails, :conditions => {:trash => true}
  scope :draft_emails, :conditions => {:draft => true}
  scope :unread_emails, :conditions => {:mark_read => false}
  
  has_and_belongs_to_many :users

  has_many :annotations
  has_many :tags, :through => :annotations, :uniq => true

  has_many :ballots, :as => :myballots


end

class Post < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 20
end
