require "date"

class Event
  TYPES = [
    :holiday,
    :sickness,
    :other_leave
  ].freeze

  attr_reader(
    :type,
    :start_date,
    :end_date,
    :half_day_at_start,
    :half_day_at_end
  )

  def initialize(
    type:,
    start_date:,
    end_date:,
    half_day_at_start: false,
    half_day_at_end: false
  )
    raise "#{type} is not a recognized event type" unless TYPES.include?(type)
    raise "#{start_date} is not a date" unless start_date.is_a?(Date)
    raise "#{end_date} is not a date" unless end_date.is_a?(Date)

    if end_date < start_date
      raise "An event cannot end before it starts"
    end

    @type = type
    @start_date = start_date
    @end_date = end_date
    @half_day_at_start = half_day_at_start
    @half_day_at_end = half_day_at_end
  end

  def matches_type?(other)
    other.type == type
  end

  def adjacent_to?(other)
    ends_at_other_start_same_day =
      end_date == other.start_date &&
      half_day_at_end &&
      other.half_day_at_start
    ends_at_other_start_different_day =
      end_date + 1 == other.start_date &&
      !half_day_at_end &&
      !other.half_day_at_start
    ends_at_other_start =
      ends_at_other_start_same_day ||
      ends_at_other_start_different_day

    other_ends_at_start_same_day =
      other.end_date == start_date &&
      other.half_day_at_end &&
      half_day_at_start
    other_ends_at_start_different_day =
      other.end_date + 1 == start_date &&
      !other.half_day_at_end &&
      !half_day_at_start
    other_ends_at_start =
      other_ends_at_start_same_day ||
      other_ends_at_start_different_day

    ends_at_other_start || other_ends_at_start
  end

  def starts_before?(other)
    starts_days_before = start_date < other.start_date
    starts_earlier_on_day =
      start_date == other.start_date &&
      !half_day_at_start &&
      other.half_day_at_start

    starts_days_before || starts_earlier_on_day
  end

  def ends_after?(other)
    ends_days_after = end_date > other.end_date
    ends_later_on_day =
      end_date == other.end_date &&
      !half_day_at_end &&
      other.half_day_at_end

    ends_days_after || ends_later_on_day
  end

  def covers?(other)
    space_around = starts_before?(other) && ends_after?(other)
    matches_start_day =
      other.start_date == start_date &&
      (
        other.half_day_at_start == half_day_at_start ||
        (!half_day_at_start && other.half_day_at_start)
      ) &&
      ends_after?(other)
    matches_end_day =
      other.end_date == end_date &&
      (
        other.half_day_at_end == half_day_at_end ||
        (!half_day_at_end && other.half_day_at_end)
      ) &&
      starts_before?(other)

    space_around || matches_start_day || matches_end_day
  end

  def overlaps?(other)
    other_starts_during =
      other.start_date < end_date ||
      (
        other.start_date == end_date &&
        (
          !half_day_at_end ||
          (half_day_at_end && !other.half_day_at_start)
        )
      )
    starts_during_other =
      start_date < other.end_date ||
      (
        start_date == other.end_date &&
        (
          !other.half_day_at_end ||
          (other.half_day_at_end && !half_day_at_start)
        )
      )
    prequel =
      starts_before?(other) &&
      !ends_after?(other) &&
      other_starts_during
    sequel =
      !starts_before?(other) &&
      ends_after?(other) &&
      starts_during_other

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
      raise "Cannot merge these events"
    end

    return self if covers?(other)
    return other if other.covers?(self)

    new_start_date = start_date
    new_half_day_at_start = half_day_at_start
    new_end_date = end_date
    new_half_day_at_end = half_day_at_end

    if other.starts_before?(self)
      new_start_date = other.start_date
      new_half_day_at_start = other.half_day_at_start
    end

    if other.ends_after?(self)
      new_end_date = other.end_date
      new_half_day_at_end = other.half_day_at_end
    end

    Event.new(
      type: type,
      start_date: new_start_date,
      end_date: new_end_date,
      half_day_at_start: new_half_day_at_start,
      half_day_at_end: new_half_day_at_end
    )
  end

  def ==(other)
    other.type == type &&
      other.start_date == start_date &&
      other.end_date == end_date &&
      other.half_day_at_start == half_day_at_start &&
      other.half_day_at_end == half_day_at_end
  end

  def as_json
    {
      "type" => type.to_s,
      "start_date" => start_date.strftime("%F"),
      "end_date" => end_date.strftime("%F"),
      "half_day_at_start" => half_day_at_start,
      "half_day_at_end" => half_day_at_end
    }
  end
end
