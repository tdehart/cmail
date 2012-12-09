# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120415141009) do

  create_table "annotations", :force => true do |t|
    t.integer  "email_id"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ballots", :force => true do |t|
    t.integer  "content_id"
    t.boolean  "over"
    t.string   "outcome"
    t.string   "vote_type"
    t.integer  "member_id"
    t.integer  "myballots_id"
    t.string   "myballots_type"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emails", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.boolean  "sent"
    t.boolean  "draft",      :default => false
    t.boolean  "trash",      :default => false
    t.boolean  "mark_read",  :default => false
    t.integer  "author_id"
    t.date     "sent_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emails_users", :id => false, :force => true do |t|
    t.integer "email_id"
    t.integer "user_id"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notifications", :force => true do |t|
    t.string   "message"
    t.boolean  "finished"
    t.boolean  "approved"
    t.integer  "ballot_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "approved"
    t.boolean  "archived",    :default => false
    t.boolean  "voteable",    :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "votes", :force => true do |t|
    t.integer  "ballot_id"
    t.integer  "user_id"
    t.boolean  "approval"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
