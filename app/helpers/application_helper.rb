module ApplicationHelper
  # The stylesheet styles flash messages by id; Devise uses :alert for errors.
  FLASH_IDS = { "alert" => "error", "success" => "notice", "info" => "notice" }.freeze

  def f_date(time, format = "%d.%m.%Y")
    time.strftime(format) if time
  end

  def f_price(amount)
    "%5.2f" % [ amount ]
  end

  def flash_id(type)
    FLASH_IDS.fetch(type.to_s, type.to_s)
  end
end
