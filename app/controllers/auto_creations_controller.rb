class AutoCreationsController < ApplicationController
  def show
    @recent_reels = current_user.reels.order(created_at: :desc)
                                     .limit(5)
  end
end
