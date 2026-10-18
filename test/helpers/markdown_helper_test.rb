require "test_helper"

class MarkdownHelperTest < ActionView::TestCase
  test "renders GitHub flavoured Markdown" do
    html = render_markdown("# Title\n\n| a | b |\n|---|---|\n| 1 | 2 |\n\n~~old~~ line\nnext")
    assert_includes html, "<h1>Title</h1>"
    assert_includes html, "<td>1</td>"
    assert_includes html, "<del>old</del>"
    assert_includes html, "<br>"
  end

  test "drops raw HTML, script links and images" do
    html = render_markdown("<script>alert(1)</script>\n\n[x](javascript:alert(1)) ![i](https://example.com/a.png) <b onclick=x>b</b>")
    assert_not_includes html, "<script"
    assert_not_includes html, "javascript:"
    assert_not_includes html, "<img"
    assert_not_includes html, "onclick"
    assert_not_includes html, "data-sourcepos"
  end

  test "links open in a new tab without a referrer" do
    html = render_markdown("[site](https://example.com)")
    assert_includes html, 'href="https://example.com"'
    assert_includes html, 'rel="noopener noreferrer nofollow"'
    assert_includes html, 'target="_blank"'
  end

  test "task boxes are clickable only in interactive mode and know their line" do
    text = "Intro\n\n- [ ] one\n- [x] two\n\n```\n- [ ] code\n```"
    interactive = Nokogiri::HTML5.fragment(render_markdown(text, interactive: true))
    boxes = interactive.css("input[type=checkbox]")
    assert_equal %w[3 4], boxes.map { |box| box["data-task-line"] }
    assert boxes.none? { |box| box["disabled"] }
    assert boxes.last["checked"]

    assert interactive.at_css("p")["data-sourcepos"].start_with?("1:1")

    read_only = Nokogiri::HTML5.fragment(render_markdown(text))
    assert read_only.css("input[type=checkbox]").all? { |box| box["disabled"] && !box["data-task-line"] }
  end

  test "plain card text for Markdown notes" do
    note = Note.new(description: "## Plan\n\n- **milk**\n- bread", markdown: true)
    assert_equal "Plan\nmilk\nbread", note_plain_text(note)
    assert_equal "## Plan", note_plain_text(Note.new(description: "## Plan"))
  end
end
