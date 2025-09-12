module Planning
  class BrandResolver
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      @user.brands.first
    end

    private

    attr_reader :user
  end
end
