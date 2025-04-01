# frozen_string_literal: true

class Operation < Sequel::Model(DB[:operations])
  many_to_one :user
  plugin :validation_helpers

  def before_validation
    self.done ||= false
    super
  end

  def validate
    super
    validates_presence %i[user_id cashback cashback_percent discount discount_percent check_summ]

    errors.add(:user_id, 'does not exist') unless User.where(id: user_id).any?

    validates_integer :user_id
    validates_numeric %i[cashback cashback_percent discount discount_percent write_off check_summ], allow_nil: true

    validates_type [TrueClass, FalseClass], :done

    validates_operator(:>=, 0, :cashback)
    validates_operator(:>=, 0, :cashback_percent)
    validates_operator(:>=, 0, :discount)
    validates_operator(:>=, 0, :discount_percent)
    validates_operator(:>=, 0, :write_off, allow_nil: true)
    validates_operator(:>=, 0, :check_summ)

    validates_operator(:<=, check_summ, :discount)
    validates_operator(:<=, check_summ, :write_off, allow_nil: true)
  end
end
