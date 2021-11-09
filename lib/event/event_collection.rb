require_relative "./event"

class EventCollection
  attr_reader :events

  def initialize(events)
    @events = events.sort_by(&:start_date)
  end

  def all_changes_from(other, compress: false)
    compress! if compress

    our_unshared_events = events.reject { |event|
      other.events.include?(event)
    }
    their_unshared_events = other.events.reject { |event|
      events.include?(event)
    }

    added = EventCollection.new(our_unshared_events)
    removed = EventCollection.new(their_unshared_events)

    added.compress! if compress

    {
      added: added,
      removed: removed
    }
  end

  def compress!
    self.events = events
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

    self
  end

  private

  attr_writer :events
end
