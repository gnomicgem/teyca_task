# frozen_string_literal: true

class SubmitOperationService
  def initialize(user, operation, write_off)
    @user = user
    @operation = operation
    @write_off = write_off
  end

  def call
    set_write_off
    set_new_total_price
    set_new_cashback
    DB.transaction do
      update_operation
      update_user_bonus
      @operation.update(done: true)
    end
    respond
  end

  private

  def update_user_bonus
    @user.update(bonus: @user.bonus - @operation.write_off.to_f.round(2) + @new_cashback.to_f.round(2))
  end

  def update_operation
    @operation.update(write_off: @write_off, check_summ: @new_total_price)
  end

  def respond
    {
      status: 200,
      message: 'Данные успешно обработаны!',
      operation: {
        user_id: @user.id,
        cashback: @new_cashback.to_f.round(2),
        cashback_percent: "#{@operation.cashback_percent.to_f.round(2)}%",
        discount: @operation.discount.to_f.round(2),
        discount_percent: "#{@operation.discount_percent.to_f.round(2)}%",
        write_off: @operation.write_off.to_f.round(2),
        check_summ: @operation.check_summ.to_f.round(2)
      }
    }
  end

  def set_write_off
    @write_off = [@operation.allowed_write_off, @write_off].min

    write_off_valid?
  end

  def set_new_total_price
    @new_total_price = @operation.check_summ - @write_off

    raise StandardError, 'Total price should not be negative' if @new_total_price.negative?
  end

  def set_new_cashback
    @new_cashback = @new_total_price * @operation.cashback_percent / 100.0
    raise StandardError, 'Cashback should not be negative' if @new_cashback.negative?
  end

  def write_off_valid?
    raise StandardError, 'Write_off is missing' unless @write_off
    raise StandardError, 'Write_off should not be negative' if @write_off.negative?

    return if @write_off <= @operation.allowed_write_off

    raise StandardError, "Not enough bonuses to write off, available: #{@operation.allowed_write_off.to_f.round(2)}"
  end
end
