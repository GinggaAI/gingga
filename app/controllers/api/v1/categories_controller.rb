class Api::V1::CategoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    categories = [
      { id: "educational", name: "Educational" },
      { id: "entertainment", name: "Entertainment" },
      { id: "motivational", name: "Motivational" },
      { id: "product_demo", name: "Product Demo" },
      { id: "behind_scenes", name: "Behind the Scenes" },
      { id: "testimonial", name: "Testimonial" },
      { id: "trending", name: "Trending Topics" },
      { id: "storytelling", name: "Storytelling" }
    ]

    render json: { categories: categories }
  end
end
