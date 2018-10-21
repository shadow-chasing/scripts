class AddArticlesCountToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :articles_count, :integer, default: 0

    User.find_each {|u| User.reset_counters(u.id, :articles_count) }
  end
end
