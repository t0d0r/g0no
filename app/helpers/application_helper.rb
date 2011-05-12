module ApplicationHelper

  def f_date(time, format="%d.%m.%Y")
    time.strftime(format) if time
  end

  def f_price(amount)
    "%5.2f" % [ amount ]
  end

end
