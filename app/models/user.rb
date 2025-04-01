# frozen_string_literal: true

class User < Sequel::Model(DB[:users])
  one_to_one :template
  one_to_many :operations

  def template
    Template[template_id]
  end
end
