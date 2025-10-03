class Product < ApplicationRecord
  belongs_to :brand, counter_cache: true
  validates :name, presence: true, uniqueness: { scope: :brand_id }
end
