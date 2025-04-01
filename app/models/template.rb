# frozen_string_literal: true

class Template < Sequel::Model(DB[:templates])
  one_to_many :users
end
