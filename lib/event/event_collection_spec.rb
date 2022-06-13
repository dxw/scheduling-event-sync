require "date"
require_relative "./event"
require_relative "./event_collection"

RSpec.describe EventCollection do
  describe ".from_array" do
    it "initalises an event collection" do
      events_array = [
        {
          "type" => "holiday",
          "start_date" => "2020-02-02",
          "end_date" => "2020-03-01",
          "half_day_at_start" => true,
          "half_day_at_end" => true
        }
      ]

      collection = EventCollection.from_array(events_array)

      expect(collection).to be_a(EventCollection)
      expect(collection.events).to eq([
        Event.new(
          type: :holiday,
          start_date: Date.new(2020, 2, 2),
          end_date: Date.new(2020, 3, 1),
          half_day_at_start: true,
          half_day_at_end: true
        )
      ])
    end
  end

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

  describe "#split_half_days" do
    it "returns a new collection with all half day events split from full day events" do
      holiday_starting_with_half_day = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 2),
        half_day_at_start: true
      )
      holiday_ending_with_half_day = Event.new(
        type: :holiday,
        start_date: Date.new(2001, 1, 1),
        end_date: Date.new(2001, 2, 2),
        half_day_at_end: true
      )
      holiday_with_both_half_days = Event.new(
        type: :holiday,
        start_date: Date.new(2002, 1, 1),
        end_date: Date.new(2002, 2, 2),
        half_day_at_start: true,
        half_day_at_end: true
      )
      holiday_with_no_half_days = Event.new(
        type: :holiday,
        start_date: Date.new(2003, 1, 1),
        end_date: Date.new(2003, 2, 2)
      )
      holiday_with_adjacent_half_days = Event.new(
        type: :holiday,
        start_date: Date.new(2004, 1, 1),
        end_date: Date.new(2004, 1, 2),
        half_day_at_start: true,
        half_day_at_end: true
      )
      holiday_with_one_full_day_and_two_half_days = Event.new(
        type: :holiday,
        start_date: Date.new(2005, 1, 1),
        end_date: Date.new(2005, 1, 3),
        half_day_at_start: true,
        half_day_at_end: true
      )

      collection = EventCollection.new([
        holiday_starting_with_half_day,
        holiday_ending_with_half_day,
        holiday_with_both_half_days,
        holiday_with_no_half_days,
        holiday_with_adjacent_half_days,
        holiday_with_one_full_day_and_two_half_days
      ])

      result = collection.split_half_days

      expect(result.events).to eq([
        # holiday_starting_with_half_day
        Event.new(
          type: :holiday,
          start_date: Date.new(2000, 1, 1),
          end_date: Date.new(2000, 1, 1),
          half_day_at_start: true,
          half_day_at_end: true
        ),
        Event.new(
          type: :holiday,
          start_date: Date.new(2000, 1, 2),
          end_date: Date.new(2000, 2, 2)
        ),

        # holiday_ending_with_half_day
        Event.new(
          type: :holiday,
          start_date: Date.new(2001, 1, 1),
          end_date: Date.new(2001, 2, 1)
        ),
        Event.new(
          type: :holiday,
          start_date: Date.new(2001, 2, 2),
          end_date: Date.new(2001, 2, 2),
          half_day_at_start: true,
          half_day_at_end: true
        ),

        # holiday_with_both_half_days
        Event.new(
          type: :holiday,
          start_date: Date.new(2002, 1, 1),
          end_date: Date.new(2002, 1, 1),
          half_day_at_start: true,
          half_day_at_end: true
        ),
        Event.new(
          type: :holiday,
          start_date: Date.new(2002, 1, 2),
          end_date: Date.new(2002, 2, 1)
        ),
        Event.new(
          type: :holiday,
          start_date: Date.new(2002, 2, 2),
          end_date: Date.new(2002, 2, 2),
          half_day_at_start: true,
          half_day_at_end: true
        ),

        holiday_with_no_half_days,

        # holiday_with_adjacent_half_days
        Event.new(
          type: :holiday,
          start_date: Date.new(2004, 1, 1),
          end_date: Date.new(2004, 1, 1),
          half_day_at_start: true,
          half_day_at_end: true
        ),
        Event.new(
          type: :holiday,
          start_date: Date.new(2004, 1, 2),
          end_date: Date.new(2004, 1, 2),
          half_day_at_start: true,
          half_day_at_end: true
        ),

        # holiday_with_one_full_day_and_two_half_days
        Event.new(
          type: :holiday,
          start_date: Date.new(2005, 1, 1),
          end_date: Date.new(2005, 1, 1),
          half_day_at_start: true,
          half_day_at_end: true
        ),
        Event.new(
          type: :holiday,
          start_date: Date.new(2005, 1, 2),
          end_date: Date.new(2005, 1, 2)
        ),
        Event.new(
          type: :holiday,
          start_date: Date.new(2005, 1, 3),
          end_date: Date.new(2005, 1, 3),
          half_day_at_start: true,
          half_day_at_end: true
        )
      ])
    end

    it "doesn't modify the events of the original" do
      holiday_with_both_half_days = Event.new(
        type: :holiday,
        start_date: Date.new(2002, 1, 1),
        end_date: Date.new(2002, 2, 2),
        half_day_at_start: true,
        half_day_at_end: true
      )

      collection = EventCollection.new([holiday_with_both_half_days])

      events = collection.events

      collection.split_half_days

      expect(collection.events).to be(events)
    end
  end

  describe "#as_json" do
    it "returns the events as json" do
      first_event = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1)
      )
      second_event = Event.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 10),
        end_date: Date.new(2000, 1, 14)
      )

      collection = EventCollection.new([first_event, second_event])
      expect(collection.as_json).to eql([first_event.as_json, second_event.as_json])
    end
  end
end
