require "test_helper"

class TextDiffTest < ActiveSupport::TestCase
  test "marks changed words" do
    assert_equal [ [ :same, "Milk, " ], [ :del, "bread," ], [ :ins, "butter," ], [ :same, " eggs" ] ],
                 TextDiff.diff("Milk, bread, eggs", "Milk, butter, eggs")
  end

  test "handles empty texts" do
    assert_equal [ [ :ins, "new text" ] ], TextDiff.diff("", "new text")
    assert_equal [ [ :del, "old" ] ], TextDiff.diff("old", nil)
    assert_equal [], TextDiff.diff(nil, nil)
  end

  test "falls back to replacing the middle of very long texts" do
    a = Array.new(1000) { |i| "a#{i}" }.join(" ")
    b = Array.new(1000) { |i| "b#{i}" }.join(" ")
    assert_equal [ [ :del, a ], [ :ins, b ] ], TextDiff.diff(a, b)
  end
end
