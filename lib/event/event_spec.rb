require "date"
require_relative "./event"

RSpec.describe Event do
  let(:start_date) { Date.new(2000, 1, 1) }
  let(:end_date) { Date.new(2000, 2, 1) }

  describe ".new" do
    it "rejects an invalid type" do
      expect {
        Event.new(
          type: :invalid,
          start_date: start_date,
          end_date: end_date
        )
      }.to raise_error("invalid is not a recognized event type")
    end

    it "rejects a non-date start date" do
      expect {
        Event.new(
          type: :holiday,
          start_date: "2000-01-01",
          end_date: end_date
        )
      }.to raise_error("2000-01-01 is not a date")
    end

    it "rejects a non-date end date" do
      expect {
        Event.new(
          type: :holiday,
          start_date: start_date,
          end_date: "2000-02-01"
        )
      }.to raise_error("2000-02-01 is not a date")
    end

    it "rejects an end date before the start date" do
      expect {
        Event.new(
          type: :holiday,
          start_date: start_date,
          end_date: start_date - 1
        )
      }.to raise_error("An event cannot end before it starts")
    end
  end

  describe "#type" do
    it "returns the initial type" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.type).to eq(:holiday)
    end

    it "is read-only" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event).not_to respond_to(:type=)
    end
  end

  describe "#start_date" do
    it "returns the initial start date" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.start_date).to eq(start_date)
    end

    it "is read-only" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event).not_to respond_to(:start_date=)
    end
  end

  describe "#end_date" do
    it "returns the initial end date" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.end_date).to eq(end_date)
    end

    it "is read-only" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event).not_to respond_to(:end_date=)
    end
  end

  describe "#half_day_at_start" do
    it "returns the initial start half day" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_start: true
      )

      expect(event.half_day_at_start).to be(true)
    end

    it "defaults to false" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.half_day_at_start).to be(false)
    end

    it "is read-only" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_start: true
      )

      expect(event).not_to respond_to(:half_day_at_start=)
    end
  end

  describe "#half_day_at_end" do
    it "returns the initial end half day" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_end: true
      )

      expect(event.half_day_at_end).to be(true)
    end

    it "defaults to false" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.half_day_at_end).to be(false)
    end

    it "is read-only" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_end: true
      )

      expect(event).not_to respond_to(:half_day_at_end=)
    end
  end

  describe "#matches_type?" do
    it "returns true when the other event is of the same type" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.matches_type?(other)).to be(true)
    end

    it "returns false when the other event is of the a different type" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :sickness,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.matches_type?(other)).to be(false)
    end
  end

  describe "#adjacent_to?" do
    subject_start_date = Date.new(2000, 6, 1)
    subject_end_date = Date.new(2000, 7, 1)

    [
      # 1 day gap
      {
        name: "returns false when the other event starts more than one day after the end of the subject",
        other: {
          start_date: subject_end_date + 2,
          end_date: subject_end_date + 30
        },
        expectation: false
      },
      {
        name: "returns false when the other event ends more than one day before the start of the subject",
        other: {
          start_date: subject_end_date - 30,
          end_date: subject_end_date - 2
        },
        expectation: false
      },

      # next/previous day
      {
        name: "returns true when the other event starts (AM) on the day after the end (PM) of the subject",
        other: {
          start_date: subject_end_date + 1,
          end_date: subject_end_date + 30,
          half_day_at_start: false
        },
        subject: {
          half_day_at_end: false
        },
        expectation: true
      },
      {
        name: "returns false when the other event starts (PM) on the day after the end (PM) of the subject",
        other: {
          start_date: subject_end_date + 1,
          end_date: subject_end_date + 30,
          half_day_at_start: true
        },
        subject: {
          half_day_at_end: false
        },
        expectation: false
      },
      {
        name: "returns false when the other event starts (PM) on the day after the end (AM) of the subject",
        other: {
          start_date: subject_end_date + 1,
          end_date: subject_end_date + 30,
          half_day_at_start: true
        },
        subject: {
          half_day_at_end: true
        },
        expectation: false
      },
      {
        name: "returns true when the other event ends (PM) on the day before the start (AM) of the subject",
        other: {
          start_date: subject_start_date - 30,
          end_date: subject_start_date - 1,
          half_day_at_end: false
        },
        subject: {
          half_day_at_start: false
        },
        expectation: true
      },
      {
        name: "returns false when the other event ends (AM) on the day before the start (AM) of the subject",
        other: {
          start_date: subject_start_date - 30,
          end_date: subject_start_date - 1,
          half_day_at_end: true
        },
        subject: {
          half_day_at_start: false
        },
        expectation: false
      },
      {
        name: "returns false when the other event ends (AM) on the day before the start (PM) of the subject",
        other: {
          start_date: subject_start_date - 30,
          end_date: subject_start_date - 1,
          half_day_at_end: true
        },
        subject: {
          half_day_at_start: true
        },
        expectation: false
      },

      # same day
      {
        name: "returns true when the other event starts (PM) on the same day as the end (AM) of the subject",
        other: {
          start_date: subject_end_date,
          end_date: subject_end_date + 30,
          half_day_at_start: true
        },
        subject: {
          half_day_at_end: true
        },
        expectation: true
      },
      {
        name: "returns true when the other event ends (AM) on the same day as the start (PM) of the subject",
        other: {
          start_date: subject_start_date - 30,
          end_date: subject_start_date,
          half_day_at_end: true
        },
        subject: {
          half_day_at_start: true
        },
        expectation: true
      },

      # same day with overlap
      {
        name: "returns false when the other event starts (AM) on the same day as the end (PM) of the subject",
        other: {
          start_date: subject_end_date,
          end_date: subject_end_date + 30,
          half_day_at_start: false
        },
        subject: {
          half_day_at_end: false
        },
        expectation: false
      },
      {
        name: "returns false when the other event ends (PM) on the same day as the start (AM) of the subject",
        other: {
          start_date: subject_start_date - 30,
          end_date: subject_start_date,
          half_day_at_end: false
        },
        subject: {
          half_day_at_start: false
        },
        expectation: false
      },

      # full day overlap
      {
        name: "returns false when the other event starts between the start and the end of the subject",
        other: {
          start_date: subject_start_date + 1,
          end_date: subject_end_date + 1
        },
        expectation: false
      },
      {
        name: "returns false when the other event ends between the start and the end of the subject",
        other: {
          start_date: subject_start_date - 1,
          end_date: subject_end_date - 1
        },
        expectation: false
      },

      # covered
      {
        name: "returns false when the other event is covered by the subject",
        other: {
          start_date: subject_start_date + 1,
          end_date: subject_end_date - 1
        },
        expectation: false
      },
      {
        name: "returns false when the other event covers the subject",
        other: {
          start_date: subject_start_date - 1,
          end_date: subject_end_date + 1
        },
        expectation: false
      }
    ].each { |test_case|
      it test_case[:name] do
        other = Event.new(
          type: :holiday,
          start_date: test_case[:other][:start_date],
          end_date: test_case[:other][:end_date],
          half_day_at_start: test_case[:other][:half_day_at_start],
          half_day_at_end: test_case[:other][:half_day_at_end]
        )
        event = Event.new(
          type: :holiday,
          start_date: subject_start_date,
          end_date: subject_end_date,
          half_day_at_start: test_case.fetch(:subject, {})[:half_day_at_start],
          half_day_at_end: test_case.fetch(:subject, {})[:half_day_at_end]
        )

        expect(event.adjacent_to?(other)).to be(test_case[:expectation])
      end
    }
  end

  describe "#starts_before?" do
    it "returns true when the other event starts the day after the start of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date + 1,
        end_date: end_date + 30
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.starts_before?(other)).to be(true)
    end

    it "returns true when the other event starts (PM) on the same day as the start (AM) of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date + 30,
        half_day_at_start: true
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_start: false
      )

      expect(event.starts_before?(other)).to be(true)
    end

    it "returns false when the other event starts (AM) on the same day as the start (PM) of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date + 30,
        half_day_at_start: false
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_start: true
      )

      expect(event.starts_before?(other)).to be(false)
    end

    it "returns false when the other event starts the day before the start of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date - 1,
        end_date: end_date + 30
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.starts_before?(other)).to be(false)
    end
  end

  describe "#ends_after?" do
    it "returns true when the other event ends the day before the end of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date - 30,
        end_date: end_date - 1
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.ends_after?(other)).to be(true)
    end

    it "returns true when the other event ends (AM) on the same day as the end (PM) of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date - 30,
        end_date: end_date,
        half_day_at_end: true
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_end: false
      )

      expect(event.ends_after?(other)).to be(true)
    end

    it "returns false when the other event ends (PM) on the same day as the end (AM) of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date - 30,
        end_date: end_date,
        half_day_at_end: false
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_end: true
      )

      expect(event.ends_after?(other)).to be(false)
    end

    it "returns false when the other event ends the day after the end of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date - 30,
        end_date: end_date + 1
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.ends_after?(other)).to be(false)
    end
  end

  describe "#covers?" do
    it "returns true when the subject starts before and ends after the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date + 1,
        end_date: end_date - 1
      )

      expect(event.covers?(other)).to be(true)
    end

    it "returns true when the subject starts before and ends at the same time as the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date + 1,
        end_date: end_date
      )

      expect(event.covers?(other)).to be(true)
    end

    it "returns false when the subject starts before and ends before the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date + 1,
        end_date: end_date + 1
      )

      expect(event.covers?(other)).to be(false)
    end

    it "returns true when the subject starts at the same time as and ends after the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date - 1
      )

      expect(event.covers?(other)).to be(true)
    end

    it "returns false when the subject starts after and ends after the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date - 1,
        end_date: end_date - 1
      )

      expect(event.covers?(other)).to be(false)
    end

    it "returns false when the subject starts after and ends before the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date - 1,
        end_date: end_date + 1
      )

      expect(event.covers?(other)).to be(false)
    end
  end

  describe "#overlaps?" do
    it "returns false when the subject starts before and ends after the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date - 1,
        end_date: end_date + 1
      )

      expect(event.overlaps?(other)).to be(false)
    end

    it "returns true when the subject starts before and ends before the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date - 1,
        end_date: end_date - 1
      )

      expect(event.overlaps?(other)).to be(true)
    end

    it "returns true when the subject starts after and ends after the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date + 1,
        end_date: end_date + 1
      )

      expect(event.overlaps?(other)).to be(true)
    end

    it "returns false when the subject starts after and ends before the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date + 1,
        end_date: end_date - 1
      )

      expect(event.overlaps?(other)).to be(false)
    end
  end

  describe "#mergeable_with?" do
    it "returns false when the subject and other event are of different types" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = instance_double(Event)

      allow(event).to receive(:matches_type?).with(other) { false }

      expect(event.mergeable_with?(other)).to be(false)
    end

    it "returns true when the subject and other event are adjacent" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = instance_double(Event)

      allow(event).to receive(:matches_type?).with(other) { true }
      allow(event).to receive(:adjacent_to?).with(other) { true }

      expect(event.mergeable_with?(other)).to be(true)
    end

    it "returns true when the subject and other event overlap" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = instance_double(Event)

      allow(event).to receive(:matches_type?).with(other) { true }
      allow(event).to receive(:adjacent_to?).with(other) { false }
      allow(event).to receive(:overlaps?).with(other) { true }

      expect(event.mergeable_with?(other)).to be(true)
    end

    it "returns true when the subject covers the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = instance_double(Event)

      allow(event).to receive(:matches_type?).with(other) { true }
      allow(event).to receive(:adjacent_to?).with(other) { false }
      allow(event).to receive(:overlaps?).with(other) { false }
      allow(event).to receive(:covers?).with(other) { true }

      expect(event.mergeable_with?(other)).to be(true)
    end

    it "returns true when the other event covers the subject" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = instance_double(Event)

      allow(event).to receive(:matches_type?).with(other) { true }
      allow(event).to receive(:adjacent_to?).with(other) { false }
      allow(event).to receive(:overlaps?).with(other) { false }
      allow(event).to receive(:covers?).with(other) { false }
      allow(other).to receive(:covers?).with(event) { true }

      expect(event.mergeable_with?(other)).to be(true)
    end

    it "returns false when the subject and other event are not adjacent, overlapping, nor covering each other" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = instance_double(Event)

      allow(event).to receive(:matches_type?).with(other) { true }
      allow(event).to receive(:adjacent_to?).with(other) { false }
      allow(event).to receive(:overlaps?).with(other) { false }
      allow(event).to receive(:covers?).with(other) { false }
      allow(other).to receive(:covers?).with(event) { false }

      expect(event.mergeable_with?(other)).to be(false)
    end
  end

  describe "#merge_with" do
    it "rejects an impossible merge" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = instance_double(Event)

      allow(event).to receive(:mergeable_with?).with(other) { false }

      expect {
        event.merge_with(other)
      }.to raise_error("Cannot merge these events")
    end

    it "returns the subject when it covers the other event" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = instance_double(Event)

      allow(event).to receive(:mergeable_with?).with(other) { true }
      allow(event).to receive(:covers?).with(other) { true }

      expect(event.merge_with(other)).to be(event)
    end

    it "returns the other event when it covers the subject" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = instance_double(Event)

      allow(event).to receive(:mergeable_with?).with(other) { true }
      allow(event).to receive(:covers?).with(other) { false }
      allow(other).to receive(:covers?).with(event) { true }

      expect(event.merge_with(other)).to be(other)
    end

    it "returns a new event with the earliest start date and matching start half day" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_start: true
      )
      before = Event.new(
        type: :holiday,
        start_date: start_date - 3,
        end_date: end_date,
        half_day_at_start: false
      )
      after = Event.new(
        type: :holiday,
        start_date: start_date + 3,
        end_date: end_date,
        half_day_at_start: false
      )

      new_before = event.merge_with(before)

      expect(new_before.start_date).to eq(start_date - 3)
      expect(new_before.half_day_at_start).to be(false)

      new_after = event.merge_with(after)

      expect(new_after.start_date).to eq(start_date)
      expect(new_after.half_day_at_start).to be(true)
    end

    it "returns a new event with the latest end date and matching end half day" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_end: true
      )
      before = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date - 3,
        half_day_at_end: false
      )
      after = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date + 3,
        half_day_at_end: false
      )

      new_before = event.merge_with(before)

      expect(new_before.end_date).to eq(end_date)
      expect(new_before.half_day_at_end).to be(true)

      new_after = event.merge_with(after)

      expect(new_after.end_date).to eq(end_date + 3)
      expect(new_after.half_day_at_end).to be(false)
    end
  end

  describe "#==" do
    it "returns true when the other event has the same initializer properties as the subject" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_start: true,
        half_day_at_end: true
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_start: true,
        half_day_at_end: true
      )

      expect(event == other).to be(true)
    end

    it "returns false when the other event has different initializer properties from the subject" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_start: true,
        half_day_at_end: true
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        half_day_at_start: false,
        half_day_at_end: false
      )

      expect(event == other).to be(false)
    end
  end

  describe "#as_json" do
    it "returns the attributes ready to be JSONified" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      expect(event.as_json).to eql(
        {
          "type" => "holiday",
          "start_date" => start_date.strftime("%F"),
          "end_date" => end_date.strftime("%F"),
          "half_day_at_end" => false,
          "half_day_at_start" => false
        }
      )
    end
  end
end
