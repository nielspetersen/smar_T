class AddStartAtAndCompletedAtToTours < ActiveRecord::Migration
  def change
    add_column :tours, :started_at, :datetime
    add_column :tours, :completed_at, :datetime
  end
end
