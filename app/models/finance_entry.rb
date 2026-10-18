class FinanceEntry < ApplicationRecord
  belongs_to :note

  attribute :date, :date, default: -> { Date.current }

  validates :amount, numericality: true
end
