require "test_helper"

# Every UI string must exist in both languages (YAML also turns keys such as
# on/off/yes/no into booleans, which this catches too).
class LocalesTest < ActiveSupport::TestCase
  # flash.actions.* comes from the responders gem (a Devise dependency), in
  # English only, and is not used by the app.
  def keys(locale, scope)
    flatten(I18n.t(scope, locale: locale)).reject { |key| scope == :flash && key.start_with?("actions.") }.sort
  end

  def flatten(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [ prefix, key ].compact.join(".")
      value.is_a?(Hash) ? flatten(value, path) : [ path ]
    end
  end

  %i[ui flash].each do |scope|
    test "#{scope} keys match in English and Bulgarian" do
      assert_equal keys(:en, scope), keys(:bg, scope)
    end
  end
end
