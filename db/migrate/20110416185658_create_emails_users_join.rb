class CreateEmailsUsersJoin < ActiveRecord::Migration
  def self.up
    create_table 'emails_users', :id => false do |t|
      t.column 'email_id', :integer
      t.column 'user_id', :integer
    end
  end

  def self.down
    drop_table 'emails_users'
  end
end
