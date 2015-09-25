class AddColumnToRepostore < ActiveRecord::Migration
  def change
  	 add_column :repostores, :name, :string
  end
end
