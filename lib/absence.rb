require "date"

class Absence
  TYPES = [:holiday, :sickness, :other_planned, :other_unplanned].freeze
  MERIDIEMS = [:am, :pm].freeze

  attr_reader :type, :start_date, :end_date, :start_meridiem, :end_meridiem

  def initialize(
    type:,
    start_date:,
    end_date:,
    start_meridiem: :am,
    end_meridiem: :pm
  )
    raise "#{type} is not a recognized absence type" unless TYPES.include?(type)
    raise "#{start_date} is not a date" unless start_date.is_a?(Date)
    raise "#{end_date} is not a date" unless end_date.is_a?(Date)

    unless MERIDIEMS.include?(start_meridiem)
      raise "#{start_meridiem} is not a recognized meridiem"
    end

    unless MERIDIEMS.include?(end_meridiem)
      raise "#{end_meridiem} is not a recognized meridiem"
    end

    @type = type
    @start_date = start_date
    @end_date = end_date
    @start_meridiem = start_meridiem
    @end_meridiem = end_meridiem
  end
end
