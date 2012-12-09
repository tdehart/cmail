class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name

  def to_s
    email
  end

  def self.autocomplete(search)
    if search
      find(:all, :conditions => ['name LIKE ?', "#{search}%"])
    else
      find(:all)
    end
  end

  has_many :memberships
  has_many :tags, :through => :memberships, :uniq => true

  has_and_belongs_to_many :emails

  has_many :votes
  has_many :ballots, :through => :votes

  
end
