class Product < ApplicationRecord
  belongs_to :brand
  validates :name, presence: true, uniqueness: { scope: :brand_id }
end
