class Annotation < ActiveRecord::Base
  belongs_to :tag
  belongs_to :email
end
