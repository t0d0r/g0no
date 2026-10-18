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
    assert_select ".card .card__title", text: "Groceries"
    assert_select ".card .amount", text: /3.75/
    assert_select "a.card--new[href=?]", new_note_path
  end

  test "uses Bulgarian when the browser asks for it" do
    sign_in users(:admin)
    get notes_url, headers: { "Accept-Language" => "bg,en;q=0.8" }
    assert_select "h1.desk__title", "Съдържание"
  end

  test "falls back to English for unsupported languages" do
    sign_in users(:admin)
    get notes_url, headers: { "Accept-Language" => "fr-FR" }
    assert_select "h1.desk__title", "Content"
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
    assert_select ".form-errors li"
  end

  test "sign-in page is a sticky with the login form" do
    get new_user_session_url
    assert_response :success
    assert_select ".sticky.auth form input[name=?]", "user[email]"
  end

  test "shows a note" do
    sign_in users(:admin)
    get note_url(@note)
    assert_response :success
    assert_select ".table-finance tr", 2
    assert_select ".note-total__value", text: /3.75/
    assert_select "form[data-note-form] [data-autosave-status]"
    assert_select "form[data-note-form] noscript input[type=submit]"
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

  test "searches notes by title or description from the menu bar" do
    sign_in users(:admin)
    get notes_url, params: { q: "holiday" }
    assert_response :success
    assert_select ".card .card__title", count: 1, text: "Trip"
    assert_select "a.card--new", count: 0
    assert_select "input[name=q][value=?]", "holiday"
  end

  test "filters notes by colour" do
    sign_in users(:admin)
    get notes_url, params: { color: "blue" }
    assert_select ".card .card__title", count: 1, text: "Trip"
    assert_select ".filter input[name=color][value=blue][checked]"
  end

  test "ignores an unknown colour filter" do
    sign_in users(:admin)
    get notes_url, params: { color: "orange" }
    assert_select ".card", 2
  end

  test "search treats LIKE wildcards literally" do
    sign_in users(:admin)
    get notes_url, params: { q: "%" }
    assert_select ".card", 0
    assert_select ".empty"
  end

  test "changes the colour of a note from the fixed set" do
    sign_in users(:admin)
    patch note_url(@note), params: { note: { color: "green" } }
    assert_redirected_to note_url(@note)
    assert_equal "green", @note.reload.color

    patch note_url(@note), params: { note: { color: "#ff0000" } }
    assert_response :unprocessable_content
    assert_equal "green", @note.reload.color
  end

  test "creates a note with a chosen colour" do
    sign_in users(:admin)
    post notes_url, params: { note: { title: "Pink one", color: "pink" } }
    assert_equal "pink", Note.find_by!(title: "Pink one").color
  end

  test "the note window has a colour menu" do
    sign_in users(:admin)
    get note_url(@note)
    assert_select ".color-menu button.swatch:not(.swatch--random)[name=?]", "note[color]", 6
    assert_select ".color-menu button[aria-pressed=true][value=yellow]"
  end

  test "cards show how many files a note has" do
    sign_in users(:admin)
    2.times { attach_file(@note) }
    get notes_url
    assert_select ".card", text: /Groceries/ do
      assert_select ".card__badge--files", text: "2"
    end
    assert_select ".card__badge--files", 1
  end

  test "delete buttons say what will be deleted" do
    sign_in users(:admin)
    attach_file(@note)
    get note_url(@note)
    assert_select "form[data-confirm-title=?][data-confirm-button=?]", "Delete this note?", "Delete note" do |forms|
      assert_match "'Groceries' will be deleted permanently, with 2 expenses and 1 file.", forms.first["data-confirm"]
    end
    assert_select "form[data-confirm-title=?]", "Delete this file?" do |forms|
      assert_match "'hello.txt' (16 Bytes)", forms.first["data-confirm"]
    end
    assert_select "dialog[data-confirm-dialog]"
  end

  test "file links open the preview dialog" do
    sign_in users(:admin)
    attachment = attach_file(@note)
    get note_url(@note)
    assert_select "a.file-link[data-preview-kind=text][data-preview-url=?]",
                  preview_file_note_path(@note, attachment_id: attachment)
    assert_select "dialog[data-preview-dialog]"
  end

  test "previews an allowed type inline" do
    sign_in users(:admin)
    attachment = attach_file(@note)
    get preview_file_note_url(@note, attachment_id: attachment)
    assert_response :success
    assert_equal "hello from g0no\n", response.body
    assert_match(/\Ainline/, response.headers["Content-Disposition"])
    assert_equal "text/plain; charset=utf-8", response.media_type + "; charset=" + response.charset
    assert_match "sandbox", response.headers["Content-Security-Policy"]
  end

  test "never previews HTML" do
    sign_in users(:admin)
    attachment = @note.note_attachments.create!(
      file: { io: StringIO.new("<script>alert(1)</script>"), filename: "x.html", content_type: "text/html" })
    get preview_file_note_url(@note, attachment_id: attachment)
    assert_response :not_found
  end

  test "serves a byte range for the preview" do
    sign_in users(:admin)
    attachment = attach_file(@note)
    get preview_file_note_url(@note, attachment_id: attachment), headers: { "Range" => "bytes=0-4" }
    assert_response :partial_content
    assert_equal "hello", response.body
    assert_equal "bytes 0-4/16", response.headers["Content-Range"]
  end

  test "shares a note with an open link" do
    sign_in users(:admin)
    post share_note_url(@note)
    assert_redirected_to note_url(@note, anchor: "sharing")
    token = @note.reload.share_token
    assert token.present?
    assert_not @note.share_password?

    sign_out :user
    get shared_note_url(token)
    assert_response :success
    assert_select "h1.note-title", "Groceries"
    assert_equal "same-origin", response.headers["Referrer-Policy"]
    assert_select "form.button_to", 0
  end

  test "a password-protected share asks for the password" do
    sign_in users(:admin)
    post share_note_url(@note), params: { share_password: "open-sesame" }
    token = @note.reload.share_token
    attachment = attach_file(@note)
    sign_out :user

    get shared_note_url(token)
    assert_select "#unlock_form"
    assert_select "h1.note-title", 0
    get shared_note_download_url(token, attachment)
    assert_redirected_to shared_note_url(token)

    post unlock_shared_note_url(token), params: { password: "wrong" }
    assert_response :unprocessable_content

    post unlock_shared_note_url(token), params: { password: "open-sesame" }
    assert_redirected_to shared_note_url(token)
    get shared_note_url(token)
    assert_select "h1.note-title", "Groceries"
    get shared_note_download_url(token, attachment)
    assert_equal "hello from g0no\n", response.body
    get shared_note_preview_url(token, attachment)
    assert_response :success
  end

  test "rejects a share password that is too short" do
    sign_in users(:admin)
    post share_note_url(@note), params: { share_password: "abc" }
    assert_nil @note.reload.share_token
    assert flash[:alert].present?
  end

  test "a new link or stopping sharing revokes the old link" do
    sign_in users(:admin)
    post share_note_url(@note)
    old_token = @note.reload.share_token
    post share_note_url(@note)
    assert_not_equal old_token, @note.reload.share_token
    get shared_note_url(old_token)
    assert_response :not_found

    delete share_note_url(@note)
    assert_nil @note.reload.share_token
  end

  test "unknown share tokens are not found" do
    get shared_note_url("nope")
    assert_response :not_found
  end

  test "shared files only come from the shared note" do
    sign_in users(:admin)
    other = attach_file(notes(:trip))
    post share_note_url(@note)
    get shared_note_download_url(@note.reload.share_token, other)
    assert_response :not_found
  end


  test "the note window links to its history" do
    sign_in users(:admin)
    get note_url(@note)
    assert_select "a.sticky__box[href=?]", history_note_path(@note)
  end

  test "history shows versions with changes and a timeline" do
    sign_in users(:admin)
    @note.versions.create!(event: "baseline", title: "Groceries", description: "Weekly shopping", color: "yellow",
                           created_at: 1.day.ago)
    patch note_url(@note), params: { note: { description: "Weekly shopping list" } }

    get history_note_url(@note)
    assert_response :success
    assert_select "body.time-capsule"
    assert_select ".capsule__card", 2
    assert_select ".capsule__card[aria-hidden=false] ins", "list"
    assert_select ".capsule__card[aria-hidden=false] .capsule__now"
    assert_select ".capsule__tick", 2
    assert_select ".capsule__card[aria-hidden=true] form[action=?]",
                  restore_version_note_path(@note, version_id: @note.versions.first)
  end

  test "history selects the version from the v parameter" do
    sign_in users(:admin)
    first = @note.versions.create!(event: "baseline", title: "Groceries", description: "old", color: "yellow",
                                   created_at: 1.day.ago)
    @note.update!(description: "new")
    get history_note_url(@note, v: first.id)
    assert_select "#version-#{first.id}[aria-hidden=false]"
    assert_select "#version-#{@note.versions.last.id}.is-future"
  end

  test "restores a version" do
    sign_in users(:admin)
    old = @note.versions.create!(event: "baseline", title: "Groceries", description: "old text", color: "green",
                                 created_at: 1.day.ago)
    post restore_version_note_url(@note, version_id: old)
    assert_redirected_to note_url(@note)
    @note.reload
    assert_equal [ "old text", "green" ], [ @note.description, @note.color ]
    assert_equal "restored", @note.versions.last.event
    assert_equal "admin", @note.versions.last.author
  end

  test "a restore that clashes with another title shows the error" do
    sign_in users(:admin)
    old = @note.versions.create!(event: "baseline", title: "Trip", description: "x", color: "yellow")
    post restore_version_note_url(@note, version_id: old)
    assert_redirected_to history_note_url(@note, v: old.id)
    assert flash[:alert].present?
    assert_equal "Groceries", @note.reload.title
  end

  test "the colour menu has a random button with another colour" do
    sign_in users(:admin)
    get note_url(@note)
    assert_select ".color-menu button.swatch--random" do |buttons|
      assert_includes Note::COLORS - [ "yellow" ], buttons.first["value"]
    end
    get new_note_url
    assert_select ".color-menu button.swatch--random[data-color-random][type=button]"
  end


  test "autosave updates a note and answers with JSON" do
    sign_in users(:admin)
    patch note_url(@note), params: { note: { title: "Groceries", description: "typed" } }, as: :json
    assert_response :success
    assert_equal note_path(@note), response.parsed_body["url"]
    assert_match(/\A\d\d:\d\d\z/, response.parsed_body["saved_at"])
    assert_equal "typed", @note.reload.description
  end

  test "autosave reports a validation error as JSON" do
    sign_in users(:admin)
    patch note_url(@note), params: { note: { title: "Trip" } }, as: :json
    assert_response :unprocessable_content
    assert_match "already", response.parsed_body["error"]
    assert_equal "Groceries", @note.reload.title
  end

  test "autosave creates a new note once it has a title" do
    sign_in users(:admin)
    assert_difference("Note.count") do
      post notes_url, params: { note: { title: "Typed in", description: "first words", color: "green" } }, as: :json
    end
    assert_response :created
    note = Note.find_by!(title: "Typed in")
    assert_equal note_path(note), response.parsed_body["url"]
    assert_equal "green", note.color
  end


  test "the note window has a copy box for the note's text" do
    sign_in users(:admin)
    get note_url(@note)
    assert_select "button.copy-note[hidden][data-copy-text=?][data-copy-title=?]", "#note_description", "#note_title"
    assert_select "textarea#note_description"
    assert_select "input#note_title"
  end

  test "a shared note can be copied too" do
    @note.share
    get shared_note_url(@note.share_token)
    assert_select "button.copy-note[data-copy-text=?]", ".shared-note .note-text"
  end


  test "saved notes can be locked; new notes cannot" do
    sign_in users(:admin)
    get note_url(@note)
    assert_select "form[data-note-form][data-lockable=true][data-locked-hint]"
    assert_select "button.lock-box[hidden][data-lock-box]"
    assert_select "#note_title[readonly]", 0
    get new_note_url
    assert_select "form[data-note-form][data-lockable=false]"
    assert_select "button.lock-box", 0
  end


  test "the Markdown switch renders the note formatted" do
    sign_in users(:admin)
    @note.update!(description: "# Shopping\n\n- [ ] milk")
    get note_url(@note)
    assert_select ".markdown-box[aria-pressed=false][value='1']"
    assert_select "[data-markdown-view]", 0

    patch note_url(@note), params: { note: { markdown: "1" } }
    assert @note.reload.markdown?
    get note_url(@note)
    assert_select ".markdown-box[aria-pressed=true][value='0']"
    assert_select "[data-markdown-view] h1", "Shopping"
    assert_select "[data-markdown-view] input[type=checkbox][data-task-line='3']:not([disabled])"
    assert_select "textarea#note_description", text: /# Shopping/
  end

  test "autosave of a Markdown note returns the rendered text" do
    sign_in users(:admin)
    @note.update!(markdown: true)
    patch note_url(@note), params: { note: { title: "Groceries", description: "- [x] milk" } }, as: :json
    assert_match 'data-task-line="1"', response.parsed_body["html"]
    assert_match "checked", response.parsed_body["html"]
  end

  test "shared Markdown notes are formatted with read-only task boxes" do
    @note.update!(markdown: true, description: "**bold**\n\n- [ ] task")
    @note.share
    get shared_note_url(@note.share_token)
    assert_select ".note-markdown strong", "bold"
    assert_select ".note-markdown input[type=checkbox][disabled]"
    assert_select ".note-text[hidden]"
  end


  test "the board is sorted by the sort button and remembers it" do
    sign_in users(:admin)
    notes(:groceries).update_columns(created_at: 3.days.ago, updated_at: 1.hour.ago)
    notes(:trip).update_columns(created_at: 2.days.ago, updated_at: 2.days.ago)

    get notes_url
    assert_equal %w[Groceries Trip], css_select(".card .card__title").map(&:text)
    assert_select "a.sort-button[data-sort=created_asc][href=?]", "/notes?sort=created_desc"

    get notes_url(sort: "created_desc")
    assert_equal %w[Trip Groceries], css_select(".card .card__title").map(&:text)

    get notes_url
    assert_select "a.sort-button[data-sort=created_desc]"
    assert_equal %w[Trip Groceries], css_select(".card .card__title").map(&:text)

    get notes_url(sort: "updated_desc")
    assert_equal %w[Groceries Trip], css_select(".card .card__title").map(&:text)
    assert_select ".card[data-created][data-updated][data-id]", 2
  end

  test "the sort link keeps the search and drops other parameters" do
    sign_in users(:admin)
    get notes_url(q: "o", color: "blue", host: "evil.example", sort: "nope")
    assert_select "a.sort-button[data-sort=created_asc][href=?]", "/notes?color=blue&q=o&sort=created_desc"
  end


  test "search, colour filter, count and sort sit in the board header" do
    sign_in users(:admin)
    get notes_url(q: "o", color: "blue")
    assert_select ".menubar input[name=q]", 0
    assert_select ".desk__header .desk__tools" do
      assert_select "form.board-search input[name=q][value=o]"
      assert_select "form.board-search input[name=color][value=blue][checked]"
      assert_select ".filter__summary", /Blue/
      assert_select ".desk__meta", /1 note/
      assert_select "a.sort-button[data-sort-button]"
    end

    get by_tag_note_url("home")
    assert_select ".desk__header form.board-search[action=?]", notes_path
  end


  test "pages load Turbo Drive without page snapshots" do
    sign_in users(:admin)
    get notes_url
    assert_select "head script[type=module][src*=turbo][data-turbo-track=reload]"
    assert_select "head meta[name=turbo-cache-control][content=no-cache]"
    assert_select "a.sort-button[data-turbo-prefetch=false]"
  end

  test "file links bypass Turbo" do
    sign_in users(:admin)
    attach_file(@note)
    get note_url(@note)
    assert_select "a.file-link[data-turbo=false]"
    assert_select "a[data-preview-download][data-turbo=false]"
  end


  test "a note can be made wider" do
    sign_in users(:admin)
    get note_url(@note)
    assert_select ".note-window:not(.note-window--wide)"
    assert_select "form[data-wide-toggle] button[name=?][value='1'][aria-pressed=false]", "note[wide]"

    assert_no_difference("@note.versions.count") do
      patch note_url(@note), params: { note: { wide: "1" } }, as: :json
    end
    assert_response :success
    assert @note.reload.wide?

    get note_url(@note)
    assert_select ".note-window.note-window--wide"
    assert_select "form[data-wide-toggle] button[value='0'][aria-pressed=true]"

    @note.share
    get shared_note_url(@note.share_token)
    assert_select ".shared-note.note-window--wide"
  end

  private

  def attach_file(note)
    note.note_attachments.create!(file: fixture_file_upload("hello.txt", "text/plain"))
  end
end
