require_relative "./event"

class EventCollection
  attr_reader :events

  def initialize(events)
    @events = events.sort_by(&:start_date)
  end

  def compress
    compressed_events = events
      .group_by(&:type)
      .flat_map { |(type, group)|
        group.each_with_object([]) { |event, list|
          if list.last&.mergeable_with?(event)
            list[list.length - 1] = event.merge_with(list.last)
          else
            list << event
          end
        }
      }
      .sort_by(&:start_date)

    self.class.new(compressed_events)
  end

  def split_half_days
    split_events = events
      .map { |event|
        next event unless event.half_day_at_start || event.half_day_at_end
        next event if event.start_date == event.end_date

        splits = []
        full_time_start_date = event.start_date
        full_time_end_date = event.end_date

        if event.half_day_at_start
          splits << Event.new(
            type: event.type,
            start_date: event.start_date,
            end_date: event.start_date,
            half_day_at_start: true,
            half_day_at_end: true
          )

          full_time_start_date = event.start_date + 1
        end

        if event.half_day_at_end
          splits << Event.new(
            type: event.type,
            start_date: event.end_date,
            end_date: event.end_date,
            half_day_at_start: true,
            half_day_at_end: true
          )

          full_time_end_date = event.end_date - 1
        end

        if full_time_start_date <= full_time_end_date
          splits << Event.new(
            type: event.type,
            start_date: full_time_start_date,
            end_date: full_time_end_date,
            half_day_at_start: false,
            half_day_at_end: false
          )
        end

        splits.uniq
      }
      .flatten
      .sort_by(&:start_date)

    self.class.new(split_events)
  end

  def +(other)
    self.class.new(events + other.events)
  end

  def as_json
    events.map(&:as_json)
  end

  private

  attr_writer :events
end
