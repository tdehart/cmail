class CreateBallots < ActiveRecord::Migration
  def self.up
    create_table :ballots do |t|
      t.integer :content_id
      t.boolean :over
      t.string :outcome
      t.string :vote_type
      t.integer :member_id
      t.integer :myballots_id
      t.string  :myballots_type
      t.integer :author_id

      t.timestamps
    end
  end

  def self.down
    drop_table :ballots
  end
end
