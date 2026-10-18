class Note < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :finance_entries, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :note_attachments, -> { order(:created_at) }, dependent: :destroy

  attribute :visited_on, :date, default: -> { Date.current }

  validates :title, presence: true, uniqueness: true

  scope :tagged_with, ->(name) { joins(:tags).where(tags: { name: name }) }

  # Tags are entered as one space-separated string.
  def tag_list
    tags.map(&:name).join(" ")
  end

  def tag_list=(value)
    names = value.to_s.split(/\s+/).compact_blank.uniq
    self.tags = names.map { |name| Tag.find_or_initialize_by(name: name) }
  end

  # Sums in Ruby so a preloaded association does not trigger a query.
  # Entries built but not yet saved (for example an invalid amount) are skipped.
  def finance_total
    finance_entries.select(&:persisted?).sum(BigDecimal("0"), &:amount)
  end
end
