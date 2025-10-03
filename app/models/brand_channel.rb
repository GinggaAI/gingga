class BrandChannel < ApplicationRecord
  belongs_to :brand, counter_cache: true
  enum :platform, { instagram: 0, tiktok: 1, youtube: 2, linkedin: 3 }
  validates :platform, presence: true, uniqueness: { scope: :brand_id }
  validates :handle, presence: true
end
