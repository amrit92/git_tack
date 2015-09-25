class CreateRepostores < ActiveRecord::Migration
  def change
    create_table :repostores do |t|

      t.timestamps null: false
    end
  end
end
