class CreateAddSettingsToRepostores < ActiveRecord::Migration
  def change
    enable_extension 'hstore'
    add_column :repostores, :settings, :hstore
    add_index :repostores, :settings, using: :gin
  end
end
