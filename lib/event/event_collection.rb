require_relative "./event"

class EventCollection
  attr_reader :events

  def initialize(events)
    @events = events.sort_by(&:start_date)
  end

  def all_changes_from(other, compress: false)
    our = compress ? self.compress : self

    our_unshared_events = our.events.reject { |event|
      other.events.include?(event)
    }
    their_unshared_events = other.events.reject { |event|
      our.events.include?(event)
    }

    added = self.class.new(our_unshared_events)
    removed = self.class.new(their_unshared_events)

    {
      added: compress ? added.compress : added,
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

  private

  attr_writer :events
end
