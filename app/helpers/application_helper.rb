module ApplicationHelper
  def f_date(time, format = "%d.%m.%Y")
    time.strftime(format) if time
  end

  def f_price(amount)
    "%5.2f" % [ amount ]
  end

  # Devise reports errors as :alert; the old app used :error.
  def flash_kind(type)
    %w[alert error].include?(type.to_s) ? "alert" : "notice"
  end
end
