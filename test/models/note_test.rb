require "test_helper"

class NoteTest < ActiveSupport::TestCase
  test "requires a unique title" do
    assert_not Note.new(title: "").valid?
    note = Note.new(title: notes(:groceries).title)
    assert_not note.valid?
    assert_includes note.errors[:title], "has already been taken"
  end

  test "tag_list splits on whitespace and reuses existing tags" do
    note = Note.create!(title: "Tagged", tag_list: "home  work home")
    assert_equal %w[home work], note.tags.map(&:name)
    assert_equal tags(:home), note.tags.first
    assert_equal "home work", note.tag_list
  end

  test "tagged_with finds notes by tag name" do
    assert_equal [ notes(:groceries) ], Note.tagged_with("home").to_a
  end

  test "finance_total sums saved entries" do
    assert_equal BigDecimal("3.75"), notes(:groceries).finance_total
    assert_equal 0, notes(:trip).finance_total
  end

  test "finance_total ignores unsaved entries" do
    note = notes(:groceries)
    note.finance_entries.build(amount: 100)
    assert_equal BigDecimal("3.75"), note.finance_total
  end

  test "visited_on defaults to today" do
    assert_equal Date.current, Note.new.visited_on
  end
end
