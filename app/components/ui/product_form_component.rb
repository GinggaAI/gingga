class Ui::ProductFormComponent < ViewComponent::Base
  def initialize(form:, product:, index:)
    @form = form
    @product = product
    @index = index
  end

  private

  attr_reader :form, :product, :index
end
