class AddSettingsToRepostore < ActiveRecord::Base
  def up
    add_column :repostores, :settings, :hstore
  end

  def down
    remove_column :repostores, :settings
  end
end
