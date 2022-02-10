require_relative "./event"

class EventCollection
  attr_reader :events

  def initialize(events)
    @events = events.sort_by(&:start_date)
  end

  def all_changes_from(other, compress: false, split_half_days: false)
    our = compress ? self.compress : self
    our = split_half_days ? our.split_half_days : our

    our_unshared_events = our.events.reject { |event|
      other.events.include?(event)
    }
    their_unshared_events = other.events.reject { |event|
      our.events.include?(event)
    }

    added = self.class.new(our_unshared_events)
    added = compress ? added.compress : added
    added = split_half_days ? added.split_half_days : added

    removed = self.class.new(their_unshared_events)

    {
      added: added,
      removed: removed
    }
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
        next event unless event.start_half_day || event.end_half_day
        next event if event.start_date == event.end_date

        splits = []
        full_time_start_date = event.start_date
        full_time_end_date = event.end_date

        if event.start_half_day
          splits << Event.new(
            type: event.type,
            start_date: event.start_date,
            end_date: event.start_date,
            start_half_day: true,
            end_half_day: true
          )

          full_time_start_date = event.start_date + 1
        end

        if event.end_half_day
          splits << Event.new(
            type: event.type,
            start_date: event.end_date,
            end_date: event.end_date,
            start_half_day: true,
            end_half_day: true
          )

          full_time_end_date = event.end_date - 1
        end

        if full_time_start_date <= full_time_end_date
          splits << Event.new(
            type: event.type,
            start_date: full_time_start_date,
            end_date: full_time_end_date,
            start_half_day: false,
            end_half_day: false
          )
        end

        splits.uniq
      }
      .flatten
      .sort_by(&:start_date)

    self.class.new(split_events)
  end

  private

  attr_writer :events
end
