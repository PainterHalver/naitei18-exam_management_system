class AddTimeToTest < ActiveRecord::Migration[6.1]
  def change
    add_column :tests, :remaining_time, :float
  end
end
