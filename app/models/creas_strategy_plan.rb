class CreasStrategyPlan < ApplicationRecord
  belongs_to :user
  belongs_to :brand
  has_many :creas_posts, dependent: :destroy

  validates :month, :objective_of_the_month, :frequency_per_week, presence: true
end
