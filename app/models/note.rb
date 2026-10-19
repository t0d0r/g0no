class Note < ApplicationRecord
  # The Stickies colour menu. Notes pick one of these; there are no custom colours.
  COLORS = %w[yellow blue green pink purple gray].freeze

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :finance_entries, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :note_attachments, -> { order(:created_at) }, dependent: :destroy
  has_many :versions, -> { order(:created_at, :id) }, class_name: "NoteVersion", dependent: :delete_all

  # The share password is optional, so has_secure_password's own presence
  # validations are off.
  has_secure_password :share_password, validations: false, reset_token: false

  attribute :visited_on, :date, default: -> { Date.current }

  validates :title, presence: true, uniqueness: true
  validates :color, inclusion: { in: COLORS }
  validates :share_password, length: { in: 6..72 }, allow_nil: true

  # Every change to title, description or colour is kept (see NoteVersion).
  after_create { NoteVersion.record(self, "created") }
  after_update :record_version, if: -> { saved_change_to_title? || saved_change_to_description? || saved_change_to_color? }

  # Open pages of the note reload themselves when it changes (live-updates.md).
  after_commit :broadcast_refresh_to_viewers, on: %i[update destroy]

  scope :tagged_with, ->(name) { joins(:tags).where(tags: { name: name }) }
  scope :shared, -> { where.not(share_token: nil) }

  # Case-insensitive match on title or description.
  scope :search, ->(query) {
    pattern = "%#{sanitize_sql_like(query.to_s.strip.downcase)}%"
    where("lower(title) LIKE :pattern OR lower(description) LIKE :pattern", pattern: pattern)
  }

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

  def shared?
    share_token.present?
  end

  def share_password?
    share_password_digest.present?
  end

  # Every call makes a new link, so sharing again revokes the old one.
  def share(password: nil)
    self.share_token = SecureRandom.base58(32)
    self.share_password = password.presence
    self.shared_at = Time.current
    save
  end

  def unshare!
    update!(share_token: nil, share_password_digest: nil, shared_at: nil)
  end

  # Puts back the title, description and colour of an older version. The
  # current state is already in the history, so a restore can be undone.
  def restore(version)
    @restored_from = version
    update(title: version.title, description: version.description, color: version.color,
           updated_from: Current.user&.display_name || updated_from)
  ensure
    @restored_from = nil
  end

  # Sends "refresh" to the note's own pages and to the page of its share link
  # (also the link it had before this save, so a revoked link shows that at
  # once). Only the signal goes over Action Cable; each page fetches its new
  # content over HTTP, where sign-in and the share checks apply. Broadcasts
  # are debounced, so a burst of autosaves sends one refresh.
  def broadcast_refresh_to_viewers
    broadcast_refresh_later
    [ share_token, share_token_before_last_save ].compact.uniq.each do |token|
      broadcast_refresh_later_to(*share_stream(token))
    end
  end

  # Stream of the share link's page, named after a hash of the token so the
  # token never shows up in Action Cable's logs or the signed stream name.
  def share_stream(token = share_token)
    [ self, :share, Digest::SHA256.hexdigest(token.to_s) ]
  end

  private

  def record_version
    event =
      if @restored_from then "restored"
      elsif saved_change_to_title? || saved_change_to_description? then "edited"
      else "recolored"
      end
    NoteVersion.record(self, event, details: @restored_from&.created_at&.iso8601)
  end
end
