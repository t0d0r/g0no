require "test_helper"

class NoteVersionTest < ActiveSupport::TestCase
  setup do
    @note = notes(:groceries)
  end

  test "creating a note records a created version" do
    note = Note.create!(title: "Fresh", description: "one", author: "admin")
    version = note.versions.sole
    assert_equal "created", version.event
    assert_equal [ "Fresh", "one", "yellow", "admin" ], [ version.title, version.description, version.color, version.author ]
  end

  test "edits and colour changes are recorded with the current user" do
    Current.user = users(:bob)
    @note.update!(description: "Weekly shopping and more")
    @note.update!(color: "pink")

    edited, recolored = @note.versions.last(2)
    assert_equal "edited", edited.event
    assert_equal "Weekly shopping and more", edited.description
    assert_equal "bob", edited.author
    assert_equal "recolored", recolored.event
    assert_equal "pink", recolored.color
  ensure
    Current.reset
  end

  test "changes that are not content are not recorded" do
    assert_no_difference("@note.versions.count") do
      @note.share
      @note.update!(visited_on: Date.new(2020, 1, 1))
    end
  end

  test "files and expenses are recorded" do
    @note.note_attachments.create!(file: { io: StringIO.new("x"), filename: "a.txt" })
    @note.finance_entries.create!(amount: 4.5, comment: "eggs")
    @note.note_attachments.last.destroy

    assert_equal [ [ "file_added", "a.txt" ], [ "expense_added", "4.50 - eggs" ], [ "file_deleted", "a.txt" ] ],
                 @note.versions.last(3).map { |version| [ version.event, version.details ] }
  end

  test "restore brings back an older version and is itself recorded" do
    old = @note.versions.create!(event: "baseline", title: "Groceries", description: "Weekly shopping", color: "blue")
    @note.update!(title: "Food", description: "changed")

    assert @note.restore(old)
    @note.reload
    assert_equal [ "Groceries", "Weekly shopping", "blue" ], [ @note.title, @note.description, @note.color ]
    restored = @note.versions.last
    assert_equal "restored", restored.event
    assert_equal old.created_at.iso8601, restored.details
    assert_not old.differs_from?(@note)
  end

  test "deleting a note deletes its history" do
    @note.update!(description: "x")
    assert_difference("NoteVersion.count", -@note.versions.count) { @note.destroy }
  end

  test "automatic saves while typing are merged into one edited entry" do
    Current.user = users(:admin)
    @note.update!(description: "a")
    assert_no_difference("@note.versions.count") do
      @note.update!(description: "ab")
      @note.update!(description: "abc")
    end
    assert_equal "abc", @note.versions.last.description

    travel NoteVersion::EDIT_SESSION + 1.minute do
      assert_difference("@note.versions.count") { @note.update!(description: "abcd") }
    end
  ensure
    Current.reset
  end

  test "edits by another person start a new entry" do
    Current.user = users(:admin)
    @note.update!(description: "mine")
    Current.user = users(:bob)
    assert_difference("@note.versions.count") { @note.update!(description: "theirs") }
  ensure
    Current.reset
  end
end
