# frozen_string_literal: true

class CheckPositionService
  attr_reader :id, :product_total, :discount_percent, :cashback_percent,
              :discount, :cashback, :max_write_off, :type, :value,
              :description

  def initialize(position, discount_percent, cashback_percent)
    @id = position['id']
    @product = Product[position['id']]
    @product_total = position['price'].to_f * position['quantity'].to_i
    @discount_percent = discount_percent
    @cashback_percent = cashback_percent
    @type = 'default'
    @description = 'Standard loyalty rules'
    @value = 0
    @max_write_off = 0
  end

  def call
    check_product_type if @product

    set_discount
    set_cashback
    set_max_write_off
    self
  end

  private

  def set_max_write_off
    return unless @product.nil? || @product.type != 'noloyalty'

    @max_write_off = [@product_total - @discount, 0].max
  end

  def set_discount
    @discount = @product_total * @discount_percent / 100.0
  end

  def set_cashback
    @cashback = (@product_total - @discount) * @cashback_percent / 100.0
  end

  def check_product_type
    case @product.type
    when 'discount'
      set_for_discount
    when 'increased_cashback'
      set_for_increased_cashback
    else
      set_for_no_loyalty
    end
  end

  def set_for_discount
    @discount_percent += @product.value.to_i
    @type = 'discount'
    @description = 'Product discount'
    @value = @product.value.to_i
  end

  def set_for_increased_cashback
    @cashback_percent += @product.value.to_i
    @type = 'cashback'
    @description = 'Product cashback'
    @value = @product.value.to_i
  end

  def set_for_no_loyalty
    @discount_percent = 0
    @cashback_percent = 0
    @type = 'noloyalty'
    @description = 'No loyalty rules apply'
    @value = 0
  end
end
