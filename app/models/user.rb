class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :api_tokens, dependent: :destroy
  has_many :reels, dependent: :destroy
  has_many :brands, dependent: :destroy
  has_many :avatars, dependent: :destroy
  has_many :voices, dependent: :destroy
  has_many :api_responses, dependent: :destroy

  belongs_to :last_brand, class_name: "Brand", optional: true

  def active_token_for(provider, preferred_mode = "production")
    api_tokens
      .where(provider: provider, is_valid: true, mode: preferred_mode)
      .first ||
      api_tokens
        .where(provider: provider, is_valid: true, mode: "test")
        .first
  end

  def current_brand
    last_brand&.persisted? ? last_brand : brands.first
  end

  def update_last_brand(brand)
    return false unless brand.is_a?(Brand) && brands.include?(brand)
    update(last_brand: brand)
  end
end
