module Planning
  class DisplayService
    def initialize(user:, brand:, strategy:, params:)
      @user = user
      @brand = brand
      @strategy = strategy
      @params = params
    end

    def call
      PlanningPresenter.new(@params, brand: @brand, current_plan: @strategy)
    end

    private

    attr_reader :user, :brand, :strategy, :params
  end
end
