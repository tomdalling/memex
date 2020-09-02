class HumanDateParser
  attr_reader :today

  def initialize(today: Date.today)
    @today = today
  end

  def call(str)
    str = str.downcase.strip
    return today if str == 'today'
    return today - 1 if str == 'yesterday'
    return today_with(mday: Integer(str)) if str.match?(/\A\d+\z/)

    parts = Date._parse(str)
    if parts.any?
      today_with(**parts)
    else
      nil
    end
  end

  private

    def today_with(mday: nil, mon: nil, year: nil)
      Date.new(
        year || today.year,
        mon || today.month,
        mday || today.day,
      )
    end
end
