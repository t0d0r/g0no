# Theme (light / dark) and text size, kept in cookies so the layout can render
# them before any script runs. application.js sets the same cookies without a
# round trip; this action is the fallback without JavaScript.
class PreferencesController < ApplicationController
  THEMES = %w[light dark].freeze
  SCALES = %w[normal big extra].freeze

  skip_before_action :authenticate_user!

  def update
    remember :theme, params[:theme].presence_in(THEMES)
    remember :scale, params[:scale].presence_in(SCALES)
    redirect_back fallback_location: root_path
  end

  private

  def remember(name, value)
    cookies.permanent[name] = { value: value, same_site: :lax } if value
  end
end
