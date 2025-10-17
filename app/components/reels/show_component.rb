module Reels
  class ShowComponent < ViewComponent::Base
    def initialize(reel:, user:)
      @reel = reel
      @user = user
      @presenter = ReelShowPresenter.new(reel, user: user)
    end

    private

    attr_reader :reel, :user, :presenter
  end
end
