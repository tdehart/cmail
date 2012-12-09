class Tag < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  scope :archived_tags, :conditions => {:archived => true}
  scope :current_tags, :conditions => {:archived => false}

  #takes an item and returns the intersection of the item.tags.users
  def self.intersection(email)
    intersection_list = []

    #first take the union of all user_ids array with Union (|) operator
    email.tags.each do |t|
      intersection_list = t.users | intersection_list
    end
    #then take the intersection of each user_ids array with the Union of them all
    email.tags.each do |t|
      intersection_list = t.users & intersection_list
    end

    return intersection_list
  end

  def to_s
    name
  end

  def self.autocomplete(search)
    if search
      find(:all, :conditions => ['name LIKE ?', "#{search}%"])
    else
      find(:all)
    end
  end

  has_many :memberships
  has_many :users, :through => :memberships, :uniq => true

  has_many :annotations
  has_many :emails, :through => :annotations, :uniq => true

  has_many :ballots, :as => :myballots
end
