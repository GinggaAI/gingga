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

  def active_token_for(provider, preferred_mode = "production")
    api_tokens
      .where(provider: provider, is_valid: true, mode: preferred_mode)
      .first ||
      api_tokens
        .where(provider: provider, is_valid: true, mode: "test")
        .first
  end
end
