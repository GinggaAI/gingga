class Brand < ApplicationRecord
  belongs_to :user
  has_many :audiences, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :brand_channels, dependent: :destroy
  has_many :creas_strategy_plans, dependent: :destroy

  validates :name, :slug, :industry, :voice, presence: true
  validates :slug, uniqueness: { scope: :user_id }
end
