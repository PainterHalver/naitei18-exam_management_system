class AddPauseTimeToTest < ActiveRecord::Migration[6.1]
  def change
    add_column :tests, :pause_time, :datetime
  end
end
