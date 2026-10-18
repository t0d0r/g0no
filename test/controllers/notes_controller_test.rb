require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @note = notes(:groceries)
  end

  test "redirects to sign in when not signed in" do
    get notes_url
    assert_redirected_to new_user_session_url
  end

  test "signs in with the username" do
    post user_session_url, params: { user: { email: "admin", password: "password" } }
    assert_redirected_to root_url
  end

  test "health check needs no sign in" do
    get rails_health_check_url
    assert_response :success
  end

  test "index lists notes with their finance total" do
    sign_in users(:admin)
    get notes_url
    assert_response :success
    assert_select ".content_line .title", text: /Groceries/
    assert_select ".content_line .amount", text: /3.75/
  end

  test "uses Bulgarian when the browser asks for it" do
    sign_in users(:admin)
    get notes_url, headers: { "Accept-Language" => "bg,en;q=0.8" }
    assert_select "h1#note-content", "Съдържание"
  end

  test "falls back to English for unsupported languages" do
    sign_in users(:admin)
    get notes_url, headers: { "Accept-Language" => "fr-FR" }
    assert_select "h1#note-content", "Content"
  end

  test "creates a note with the current user as author" do
    sign_in users(:admin)
    assert_difference("Note.count") do
      post notes_url, params: { note: { title: "New note", description: "text" } }
    end
    assert_redirected_to notes_url
    assert_equal "admin", Note.find_by!(title: "New note").author
  end

  test "does not create a note without a title" do
    sign_in users(:admin)
    assert_no_difference("Note.count") do
      post notes_url, params: { note: { title: "" } }
    end
    assert_response :unprocessable_content
  end

  test "shows a note" do
    sign_in users(:admin)
    get note_url(@note)
    assert_response :success
    assert_select ".table-finance tr", 2
    assert_select ".big-finance .total", text: /3.75/
  end

  test "updates title and description" do
    sign_in users(:admin)
    patch note_url(@note), params: { note: { title: "Food", description: "changed" } }
    assert_redirected_to note_url(@note)
    @note.reload
    assert_equal "Food", @note.title
    assert_equal "admin", @note.updated_from
  end

  test "adds a finance entry" do
    sign_in users(:admin)
    assert_difference("@note.finance_entries.count") do
      patch note_url(@note), params: { finance: { date: "2026-10-03", amount: "4.5", comment: "eggs" } }
    end
    entry = @note.finance_entries.first
    assert_equal BigDecimal("4.5"), entry.amount
    assert_equal Date.new(2026, 10, 3), entry.date
    assert_equal "admin", entry.author
  end

  test "rejects a finance entry with an invalid amount" do
    sign_in users(:admin)
    assert_no_difference("FinanceEntry.count") do
      patch note_url(@note), params: { finance: { date: "2026-10-03", amount: "lots", comment: "?" } }
    end
    assert_response :unprocessable_content
  end

  test "uploads, downloads and deletes an attachment" do
    sign_in users(:admin)
    file = fixture_file_upload("hello.txt", "text/plain")
    assert_difference("NoteAttachment.count") do
      patch note_url(@note), params: { note: { attachments: [ file ], attachment_comment: "greeting" } }
    end
    attachment = @note.note_attachments.last
    assert_equal "greeting", attachment.comment
    assert_equal "hello.txt", attachment.filename.to_s

    get download_file_note_url(@note, attachment_id: attachment)
    assert_response :success
    assert_equal "hello from g0no\n", response.body
    assert_match(/attachment; filename="hello.txt"/, response.headers["Content-Disposition"])

    assert_difference("NoteAttachment.count", -1) do
      delete delete_file_note_url(@note, attachment_id: attachment)
    end
    assert_redirected_to note_url(@note)
  end

  test "downloading an attachment requires sign in" do
    get download_file_note_url(@note, attachment_id: 1)
    assert_redirected_to new_user_session_url
  end

  test "lists notes by tag" do
    sign_in users(:admin)
    get by_tag_note_url("home")
    assert_response :success
    assert_select "h2", "Groceries"
  end

  test "destroys a note" do
    sign_in users(:admin)
    assert_difference("Note.count", -1) do
      delete note_url(@note)
    end
    assert_redirected_to notes_url
  end
end
