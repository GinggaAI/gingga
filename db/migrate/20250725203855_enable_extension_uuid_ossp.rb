class EnableExtensionUuidOssp < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'uuid-ossp' unless extension_enabled?('uuid-ossp')
  end
end
