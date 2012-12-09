class CreateEmails < ActiveRecord::Migration
  def self.up
    create_table :emails do |t|
      t.string :title
      t.text :body
      t.boolean :sent
      t.boolean :draft, :default => false
      t.boolean :trash, :default => false
      t.boolean :mark_read, :default => false
      t.integer :author_id
      t.date :sent_time
      
      t.timestamps
    end
  end

  def self.down
    drop_table :emails
  end
end
