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

    if end_date < start_date
      raise "An absence cannot end before it starts"
    end

    if start_date == end_date
      if start_meridiem == end_meridiem
        raise "An absence cannot end in the same meridiem on the same day as it starts"
      elsif start_meridiem == :pm && end_meridiem == :am
        raise "An absence cannot end before it starts"
      end
    end

    @type = type
    @start_date = start_date
    @end_date = end_date
    @start_meridiem = start_meridiem
    @end_meridiem = end_meridiem
  end

  def matches_type?(other)
    other.type == type
  end

  def adjacent_to?(other)
    ends_at_other_start =
      end_date + 1 == other.start_date || (
        end_date == other.start_date &&
        end_meridiem == :am &&
        other.start_meridiem == :pm
      )
    other_ends_at_start =
      other.end_date + 1 == start_date || (
        other.end_date == start_date &&
        other.end_meridiem == :am &&
        start_meridiem == :pm
      )

    ends_at_other_start || other_ends_at_start
  end

  def starts_before?(other)
    starts_days_before = start_date < other.start_date
    starts_earlier_on_day =
      start_date == other.start_date &&
      start_meridiem == :am &&
      other.start_meridiem == :pm

    starts_days_before || starts_earlier_on_day
  end

  def ends_after?(other)
    ends_days_after = end_date > other.end_date
    ends_later_on_day =
      end_date == other.end_date &&
      end_meridiem == :pm &&
      other.end_meridiem == :am

    ends_days_after || ends_later_on_day
  end

  def covers?(other)
    space_around = starts_before?(other) && ends_after?(other)
    matches_start_day =
      other.start_date == start_date &&
      (
        other.start_meridiem == start_meridiem ||
        (start_meridiem == :am && other.start_meridiem == :pm)
      ) &&
      ends_after?(other)
    matches_end_day =
      other.end_date == end_date &&
      (
        other.end_meridiem == end_meridiem ||
        (end_meridiem == :pm && other.end_meridiem == :am)
      ) &&
      starts_before?(other)

    space_around || matches_start_day || matches_end_day
  end

  def overlaps?(other)
    prequel =
      starts_before?(other) &&
      other.ends_after?(self) &&
      (
        other.start_date < end_date ||
        (
          other.start_date == end_date &&
          (other.start_meridiem == end_meridiem || other.start_meridiem == :am)
        )
      )
    sequel =
      other.starts_before?(self) &&
      ends_after?(other) &&
      (
        start_date < other.end_date ||
        (
          start_date == other.end_date &&
          (start_meridiem == other.end_meridiem || start_meridiem == :am)
        )
      )

    prequel || sequel
  end

  def mergeable_with?(other)
    matches_type?(other) && (
      adjacent_to?(other) ||
      overlaps?(other) ||
      covers?(other) ||
      other.covers?(self)
    )
  end

  def merge_with(other)
    unless mergeable_with?(other)
      raise "Cannot merge these absences"
    end

    return self if covers?(other)
    return other if other.covers?(self)

    new_start_date = start_date
    new_start_meridiem = start_meridiem
    new_end_date = end_date
    new_end_meridiem = end_meridiem

    if other.starts_before?(self)
      new_start_date = other.start_date
      new_start_meridiem = other.start_meridiem
    end

    if other.ends_after?(self)
      new_end_date = other.end_date
      new_end_meridiem = other.end_meridiem
    end

    Absence.new(
      type: type,
      start_date: new_start_date,
      end_date: new_end_date,
      start_meridiem: new_start_meridiem,
      end_meridiem: new_end_meridiem
    )
  end
end
