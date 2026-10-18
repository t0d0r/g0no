module ApplicationHelper
  def f_date(time, format = "%d.%m.%Y")
    time.strftime(format) if time
  end

  def f_price(amount)
    "%5.2f" % [ amount ]
  end

  # Cookie values set by the sun/moon switch and the text size menu.
  def theme_preference
    cookies[:theme].presence_in(PreferencesController::THEMES)
  end

  def scale_preference
    cookies[:scale].presence_in(PreferencesController::SCALES) || "normal"
  end

  # data-* attributes for a form that asks before submitting; the confirm
  # dialog (partials/_confirm_dialog) shows the title, message and button.
  def confirm_data(title:, body:, button:)
    { confirm: body, confirm_title: title, confirm_button: button }
  end

  # Devise reports errors as :alert; the old app used :error.
  def flash_kind(type)
    %w[alert error].include?(type.to_s) ? "alert" : "notice"
  end
end
