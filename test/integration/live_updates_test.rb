require "test_helper"

# Open note pages and share pages reload themselves when the note changes
# (specs/live-updates.md).
class LiveUpdatesTest < ActionDispatch::IntegrationTest
  setup do
    @note = notes(:groceries)
  end

  test "note pages subscribe to the note's stream" do
    sign_in users(:admin)
    get note_url(@note)
    assert_select "turbo-cable-stream-source[signed-stream-name=?]", signed_stream_name(@note)
    get edit_note_url(@note)
    assert_select "turbo-cable-stream-source[signed-stream-name=?]", signed_stream_name(@note)
    assert_select "meta[name=turbo-refresh-scroll][content=preserve]"
  end

  test "a share page subscribes to a stream that does not contain the token" do
    @note.share
    get shared_note_url(@note.share_token)
    assert_select "turbo-cable-stream-source[signed-stream-name=?]", signed_stream_name(@note.share_stream)
    assert_not_includes Base64.decode64(signed_stream_name(@note.share_stream)), @note.share_token
  end

  test "a locked share page has no stream until it is unlocked" do
    @note.share(password: "open-sesame")
    get shared_note_url(@note.share_token)
    assert_select "#unlock_form"
    assert_select "turbo-cable-stream-source", 0
  end

  test "saving a note sends one refresh to its pages and its share page" do
    @note.share
    assert_turbo_stream_broadcasts @note, count: 1 do
      assert_turbo_stream_broadcasts @note.share_stream, count: 1 do
        perform_enqueued_jobs { @note.update!(description: "milk, bread") }
      end
    end
    streams = capture_turbo_stream_broadcasts(@note) { perform_enqueued_jobs { @note.update!(color: "blue") } }
    assert_equal [ "refresh" ], streams.map { |stream| stream["action"] }
  end

  test "the refresh names the request that made the change" do
    sign_in users(:admin)
    payloads = capture_turbo_stream_broadcasts(@note) do
      perform_enqueued_jobs do
        patch note_url(@note), params: { note: { description: "eggs" } }, as: :json,
                               headers: { "X-Turbo-Request-Id" => "req-123" }
      end
    end
    assert_response :success
    assert_equal "eggs", @note.reload.description
    assert_equal "req-123", payloads.sole["request-id"]
  end

  test "a revoked link's page is told to refresh" do
    @note.share
    old_stream = @note.share_stream
    assert_turbo_stream_broadcasts old_stream, count: 1 do
      perform_enqueued_jobs { @note.unshare! }
    end
  end

  test "files and expenses refresh the note's pages" do
    assert_turbo_stream_broadcasts @note do
      perform_enqueued_jobs do
        @note.note_attachments.create!(file: fixture_file_upload("hello.txt", "text/plain"))
      end
    end
    assert_turbo_stream_broadcasts @note do
      perform_enqueued_jobs { @note.finance_entries.create!(amount: 3) }
    end
  end

  test "a deleted note's page goes to the board" do
    sign_in users(:admin)
    id = @note.id
    @note.destroy!
    get note_url(id)
    assert_redirected_to notes_url
    assert_equal I18n.t("flash.note_gone"), flash[:alert]
    patch note_url(id), params: { note: { description: "x" } }
    assert_response :not_found
  end
end
