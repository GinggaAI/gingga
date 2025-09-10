class Avatar < ApplicationRecord
  belongs_to :user

  validates :avatar_id, presence: true
  validates :name, presence: true
  validates :provider, presence: true, inclusion: { in: %w[heygen kling] }
  validates :avatar_id, uniqueness: { scope: [ :user_id, :provider ] }
  validates :status, inclusion: { in: %w[active inactive] }

  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :active, -> { where(status: "active") }
  scope :by_status, ->(status) { where(status: status) }

  def active?
    status == "active"
  end

  def to_api_format
    {
      id: avatar_id,
      name: name,
      preview_image_url: preview_image_url,
      gender: gender,
      is_public: is_public,
      provider: provider
    }
  end
end
