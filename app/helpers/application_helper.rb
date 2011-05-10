module ApplicationHelper

  def f_date(time, format="%d.%m.%Y")
    time.strftime(format) if time
  end

end
