class Notification < ActiveRecord::Base
  attr_accessible :message, :finished, :approved

  belongs_to :ballot
end
