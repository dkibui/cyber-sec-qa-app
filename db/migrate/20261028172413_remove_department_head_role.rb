class RemoveDepartmentHeadRole < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE users SET role = 4 WHERE role = 3"
  end

  def down
    # irreversible: former department heads are now reviewers
  end
end
