class AddLogInputUrlToResources < ActiveRecord::Migration[5.2]
  def change
    add_column :resources, :log_input_url_ciphertext, :text
  end
end
