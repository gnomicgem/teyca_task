# frozen_string_literal: true

require_relative 'check_position_service'

class CreateOperationService
  def initialize(user, positions)
    @user = user
    @positions = positions
    @template = @user.template
    @total_price = 0
    @total_discount = 0
    @total_cashback = 0
    @available_write_off = 0
    @operation_positions = []
  end

  def call
    parse_positions
    limit_total_discount
    set_total_discount_percent
    set_total_cashback_percent
    set_final_price
    set_available_write_off
    create_operation
    respond
  end

  private

  def respond
    {
      status: 200,
      user: {
        id: @user.id,
        template_id: @user.template.id,
        name: @user.name,
        bonus: @user.bonus.to_f.round(2)
      },
      operation_id: @operation.id,
      summ: @final_price,
      positions: @operation_positions,
      discount: {
        summ: @total_discount,
        value: "#{@total_discount_percent}%"
      },
      cashback: {
        existed_summ: @user.bonus.to_f.round(2),
        allowed_summ: @available_write_off,
        value: "#{@total_cashback_percent}%",
        will_add: @total_cashback
      }
    }
  end

  def create_operation
    @operation = Operation.create(
      user_id: @user.id,
      cashback: @total_cashback,
      cashback_percent: @total_cashback_percent,
      discount: @total_discount,
      discount_percent: @total_discount_percent,
      check_summ: @final_price,
      allowed_write_off: @available_write_off
    )
  end

  def parse_positions
    @positions.each do |position|
      retrieved_position = CheckPositionService.new(
        position,
        @template.discount,
        @template.cashback
      ).call

      increase_operation(retrieved_position)

      add_operation_position(retrieved_position)
    end
  end

  def limit_total_discount
    @total_discount = [@total_discount, @total_price].min

    raise StandardError, 'Total discount is missing' unless @total_discount
    raise StandardError, 'Total discount should not be negative' if @total_discount.negative?
  end

  def set_total_discount_percent
    @total_discount_percent = @total_price.positive? ? ((@total_discount / @total_price) * 100).round(2) : 0

    raise StandardError, 'Total discount percent is missing' unless @total_discount_percent
    raise StandardError, 'Total discount percent should not be negative' if @total_discount_percent.negative?
  end

  def set_total_cashback_percent
    @total_cashback_percent = @total_price.positive? ? ((@total_cashback / @total_price) * 100).round(2) : 0

    raise StandardError, 'Total cashback percent is missing' unless @total_cashback_percent
    raise StandardError, 'Total cashback percent should not be negative' if @total_cashback_percent.negative?
  end

  def set_final_price
    @final_price = [@total_price - @total_discount, 0].max

    raise StandardError, 'Final price is missing' unless @final_price
    raise StandardError, 'Final price should not be negative' if @final_price.negative?
  end

  def set_available_write_off
    @available_write_off = [@user.bonus, @available_write_off].min

    raise StandardError, 'Available write off is missing' unless @available_write_off
    raise StandardError, 'Available write off should not be negative' if @available_write_off.negative?
  end

  def increase_operation(retrieved_position)
    @total_price += retrieved_position.product_total
    @total_discount += retrieved_position.discount
    @total_cashback += retrieved_position.cashback
    @available_write_off += retrieved_position.max_write_off
  end

  def add_operation_position(retrieved_position)
    @operation_positions << {
      id: retrieved_position.id,
      type: retrieved_position.type,
      value: retrieved_position.value,
      description: retrieved_position.description,
      discount_percent: retrieved_position.discount_percent,
      discount: retrieved_position.discount
    }
  end
end
