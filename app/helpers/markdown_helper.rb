# Renders note text written in Markdown (GitHub flavoured: tables, task
# lists, strikethrough, autolinks). Raw HTML in the text is dropped by the
# renderer, the result goes through Rails' sanitizer with a small allow-list,
# and links open in a new tab without a referrer. Images are not allowed, so
# a note cannot load content from other sites.
module MarkdownHelper
  MARKDOWN_OPTIONS = {
    parse: { smart: false },
    render: { unsafe: false, hardbreaks: true },
    extension: { table: true, tasklist: true, strikethrough: true, autolink: true, header_ids: nil, footnotes: false }
  }.freeze

  MARKDOWN_TAGS = %w[h1 h2 h3 h4 h5 h6 p br hr strong em del code pre blockquote ul ol li a
                     table thead tbody tr th td input].freeze
  MARKDOWN_ATTRIBUTES = %w[href type checked disabled align start data-sourcepos].freeze

  # interactive: task list check boxes can be clicked; each carries
  # data-task-line, the line of its "- [ ]" in the text (application.js
  # flips it there), and blocks keep data-sourcepos ("line:col-line:col")
  # so a double-click can put the caret at the same place in the text.
  # Otherwise check boxes are read-only and no positions are kept.
  def render_markdown(text, interactive: false)
    options = MARKDOWN_OPTIONS.merge(render: MARKDOWN_OPTIONS[:render].merge(sourcepos: true))
    html = Commonmarker.to_html(text.to_s, options: options, plugins: { syntax_highlighter: nil })
    html = sanitize(html, tags: MARKDOWN_TAGS, attributes: MARKDOWN_ATTRIBUTES)
    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css("a").each do |link|
      link.remove_attribute("href") if link["href"].blank?
      link["rel"] = "noopener noreferrer nofollow"
      link["target"] = "_blank"
    end
    fragment.css("input").each do |input|
      next input.remove unless input["type"] == "checkbox"

      line = input.ancestors("li").first&.[]("data-sourcepos").to_s.to_i
      if interactive && line.positive?
        input.remove_attribute("disabled")
        input["data-task-line"] = line.to_s
      else
        input["disabled"] = "disabled"
      end
    end
    fragment.css("[data-sourcepos]").each { |element| element.remove_attribute("data-sourcepos") } unless interactive
    fragment.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  # Card text on the board: plain text, without Markdown syntax for
  # Markdown notes.
  def note_plain_text(note)
    note.markdown? ? strip_tags(render_markdown(note.description)).squeeze("\n").strip : note.description.to_s
  end
end
