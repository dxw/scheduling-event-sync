require "date"
require_relative "./event"
require_relative "./event_collection"

RSpec.describe EventCollection do
  describe "#events" do
    it "returns the events, sorted by start date" do
      earliest = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1)
      )
      middle = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 10),
        end_date: Date.new(2000, 1, 14)
      )
      latest = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 2, 10),
        end_date: Date.new(2000, 3, 1)
      )

      collection = EventCollection.new([middle, latest, earliest])

      expect(collection.events).to eq([earliest, middle, latest])
    end

    it "is read-only" do
      collection = EventCollection.new([])

      expect(collection).not_to respond_to(:events=)
    end
  end

  describe "#all_changes_from" do
    let(:ours_a) {
      Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1)
      )
    }
    let(:ours_b) {
      Event.new(
        type: :sickness,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1)
      )
    }
    let(:ours_c) {
      Event.new(
        type: :sickness,
        start_date: Date.new(2000, 1, 4),
        end_date: Date.new(2000, 3, 1)
      )
    }
    let(:theirs_a) {
      Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1),
        start_half_day: true
      )
    }
    let(:theirs_b) {
      Event.new(
        type: :sickness,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1),
        end_half_day: true
      )
    }
    let(:theirs_c) {
      Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 4),
        end_date: Date.new(2000, 3, 1)
      )
    }
    let(:shared_a) {
      Event.new(
        type: :holiday,
        start_date: Date.new(2000, 4, 1),
        end_date: Date.new(2000, 5, 1)
      )
    }
    let(:shared_b) {
      Event.new(
        type: :holiday,
        start_date: Date.new(2000, 5, 1),
        end_date: Date.new(2000, 6, 1)
      )
    }

    let(:ours) {
      EventCollection.new([
        ours_a,
        ours_b,
        ours_c,
        shared_a,
        shared_b
      ])
    }
    let(:theirs) {
      EventCollection.new([
        theirs_a,
        theirs_b,
        theirs_c,
        shared_a,
        shared_b
      ])
    }

    it "returns all events in ours not found in theirs as additions" do
      result = ours.all_changes_from(theirs)

      expect(result[:added].events).to eq([ours_a, ours_b, ours_c])
    end

    it "returns all events in theirs not found in ours as removals" do
      result = ours.all_changes_from(theirs)

      expect(result[:removed].events).to eq([theirs_a, theirs_b, theirs_c])
    end

    it "doesn't include any shared events in additions and removals" do
      result = ours.all_changes_from(theirs)

      expect(result[:added].events).not_to include(shared_a)
      expect(result[:added].events).not_to include(shared_b)
      expect(result[:removed].events).not_to include(shared_a)
      expect(result[:removed].events).not_to include(shared_b)
    end

    it "returns all events in ours after compression not found in theirs as additions when compression is enabled" do
      result = ours.all_changes_from(theirs, compress: true)

      expect(result[:added].events).to eq([
        ours_a,
        Event.new(
          type: ours_b.type,
          start_date: ours_b.start_date,
          end_date: ours_c.end_date
        ),
        Event.new(
          type: shared_a.type,
          start_date: shared_a.start_date,
          end_date: shared_b.end_date
        )
      ])
    end

    it "returns all events in theirs not found in ours after compression as removals when compression is enabled" do
      result = ours.all_changes_from(theirs, compress: true)

      expect(result[:removed].events).to eq([
        theirs_a, theirs_b, theirs_c, shared_a, shared_b
      ])
    end
  end

  describe "#compress" do
    it "returns a new collection with all mergeable events merged" do
      mergeable_holiday_1a = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1)
      )
      mergeable_holiday_1b = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 10),
        end_date: Date.new(2000, 1, 14)
      )
      mergeable_holiday_2a = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 3, 1),
        end_date: Date.new(2000, 4, 1)
      )
      mergeable_holiday_2b = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 4, 1),
        end_date: Date.new(2000, 8, 1)
      )
      mergeable_holiday_2c = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 5, 2),
        end_date: Date.new(2000, 6, 1)
      )
      mergeable_holiday_2d = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 3, 2),
        end_date: Date.new(2000, 7, 1)
      )
      solo_holiday = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 8, 3),
        end_date: Date.new(2000, 9, 1)
      )
      unmergeable_sickness = Event.new(
        type: :sickness,
        start_date: Date.new(2000, 1, 10),
        end_date: Date.new(2000, 5, 1)
      )

      collection = EventCollection.new([
        mergeable_holiday_1a,
        mergeable_holiday_1b,
        mergeable_holiday_2a,
        mergeable_holiday_2b,
        mergeable_holiday_2c,
        mergeable_holiday_2d,
        solo_holiday,
        unmergeable_sickness
      ])

      result = collection.compress

      expect(result.events).to eq([
        mergeable_holiday_1a,
        unmergeable_sickness,
        Event.new(
          type: :holiday,
          start_date: Date.new(2000, 3, 1),
          end_date: Date.new(2000, 8, 1)
        ),
        solo_holiday
      ])
    end

    it "doesn't modify the events of the original" do
      mergeable_holiday_a = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1)
      )
      mergeable_holiday_b = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 10),
        end_date: Date.new(2000, 1, 14)
      )

      collection = EventCollection.new([mergeable_holiday_a, mergeable_holiday_b])

      events = collection.events

      collection.compress

      expect(collection.events).to be(events)
    end
  end
end
