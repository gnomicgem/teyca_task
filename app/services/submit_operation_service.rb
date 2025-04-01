# frozen_string_literal: true

class SubmitOperationService
  def initialize(operation, write_off)
    @operation = operation
    @write_off = write_off
  end

  def call
    set_write_off
    set_new_total_price
    set_new_cashback
    update_operation
    respond
  end

  private

  def update_operation
    @operation.update(write_off: @write_off, check_summ: @new_total_price)
  end

  def respond
    {
      status: 'success',
      message: 'Operation confirmed',
      operation: {
        user_id: @operation.user_id,
        cashback: @new_cashback.to_f.round(2),
        total_cashback_percent: @operation.cashback_percent.to_f.round(2),
        total_discount: @operation.discount.to_f.round(2),
        total_discount_percent: @operation.discount_percent.to_f.round(2),
        write_off: @operation.write_off.to_f.round(2),
        final_price: @operation.check_summ.to_f.round(2)
      }
    }
  end

  def set_write_off
    @write_off = [@operation.check_summ, @write_off].min

    write_off_valid?
  end

  def set_new_total_price
    @new_total_price = @operation.check_summ - @write_off

    raise StandardError, 'Total price should not be negative' if @new_total_price.negative?
  end

  def set_new_cashback
    @new_cashback = @operation.cashback

    raise StandardError, 'Cashback should not be negative' if @new_cashback.negative?
  end

  def write_off_valid?
    raise StandardError, 'Write_off is missing' unless @write_off
    raise StandardError, 'Write_off should not be negative' if @write_off.negative?

    return if @write_off <= @operation.allowed_write_off

    raise StandardError, "Not enough bonuses to write off, available: #{@operation.allowed_write_off.to_f.round(2)}"
  end
end
