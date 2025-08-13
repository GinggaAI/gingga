class Api::V1::FormatsController < ApplicationController
  before_action :authenticate_user!

  def index
    formats = [
      { id: "short_vertical", name: "Short Vertical (9:16)", description: "Perfect for TikTok, Instagram Reels, YouTube Shorts" },
      { id: "square", name: "Square (1:1)", description: "Ideal for Instagram feed posts" },
      { id: "horizontal", name: "Horizontal (16:9)", description: "Great for YouTube, Facebook videos" },
      { id: "story", name: "Story (9:16)", description: "Optimized for Instagram/Facebook Stories" }
    ]

    render json: { formats: formats }
  end
end
