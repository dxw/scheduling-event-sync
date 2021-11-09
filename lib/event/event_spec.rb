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

    it "rejects an end meridiem before the start meridiem when the start and end dates are the same" do
      expect {
        Event.new(
          type: :holiday,
          start_date: start_date,
          end_date: start_date,
          start_meridiem: :pm,
          end_meridiem: :am
        )
      }.to raise_error("An event cannot end before it starts")
    end

    it "rejects an invalid start meridiem" do
      expect {
        Event.new(
          type: :holiday,
          start_date: start_date,
          end_date: end_date,
          start_meridiem: :invalid
        )
      }.to raise_error("invalid is not a recognized meridiem")
    end

    it "rejects an invalid end meridiem" do
      expect {
        Event.new(
          type: :holiday,
          start_date: start_date,
          end_date: end_date,
          end_meridiem: :invalid
        )
      }.to raise_error("invalid is not a recognized meridiem")
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

  describe "#start_meridiem" do
    it "returns the initial start meridiem" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :pm
      )

      expect(event.start_meridiem).to eq(:pm)
    end

    it "defaults to AM" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(event.start_meridiem).to eq(:am)
    end

    it "is read-only" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :pm
      )

      expect(event).not_to respond_to(:start_meridiem=)
    end
  end

  describe "#end_meridiem" do
    it "returns the initial end meridiem" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        end_meridiem: :am
      )

      expect(event.end_meridiem).to eq(:am)
    end

    it "is read-only" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        end_meridiem: :am
      )

      expect(event).not_to respond_to(:end_meridiem=)
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
          start_meridiem: :am
        },
        subject: {
          end_meridiem: :pm
        },
        expectation: true
      },
      {
        name: "returns true when the other event ends (PM) on the day before the start (AM) of the subject",
        other: {
          start_date: subject_start_date - 30,
          end_date: subject_start_date - 1,
          end_meridiem: :pm
        },
        subject: {
          start_meridiem: :am
        },
        expectation: true
      },

      # same day
      {
        name: "returns true when the other event starts (PM) on the same day as the end (AM) of the subject",
        other: {
          start_date: subject_end_date,
          end_date: subject_end_date + 30,
          start_meridiem: :pm
        },
        subject: {
          end_meridiem: :am
        },
        expectation: true
      },
      {
        name: "returns true when the other event ends (AM) on the same day as the start (PM) of the subject",
        other: {
          start_date: subject_start_date - 30,
          end_date: subject_start_date,
          end_meridiem: :am
        },
        subject: {
          start_meridiem: :pm
        },
        expectation: true
      },

      # same day with overlap
      {
        name: "returns false when the other event starts (AM) on the same day as the end (PM) of the subject",
        other: {
          start_date: subject_end_date,
          end_date: subject_end_date + 30,
          start_meridiem: :am
        },
        subject: {
          end_meridiem: :pm
        },
        expectation: false
      },
      {
        name: "returns false when the other event ends (PM) on the same day as the start (AM) of the subject",
        other: {
          start_date: subject_start_date - 30,
          end_date: subject_start_date,
          end_meridiem: :pm
        },
        subject: {
          start_meridiem: :am
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
          start_meridiem: test_case[:other][:start_meridiem] || :am,
          end_meridiem: test_case[:other][:end_meridiem] || :pm
        )
        event = Event.new(
          type: :holiday,
          start_date: subject_start_date,
          end_date: subject_end_date,
          start_meridiem: test_case.fetch(:subject, {})[:start_meridiem] || :am,
          end_meridiem: test_case.fetch(:subject, {})[:end_meridiem] || :pm
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
        start_meridiem: :pm
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :am
      )

      expect(event.starts_before?(other)).to be(true)
    end

    it "returns false when the other event starts (AM) on the same day as the start (PM) of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date + 30,
        start_meridiem: :am
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :pm
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
        end_meridiem: :am
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        end_meridiem: :pm
      )

      expect(event.ends_after?(other)).to be(true)
    end

    it "returns false when the other event ends (PM) on the same day as the end (AM) of the subject" do
      other = Event.new(
        type: :holiday,
        start_date: start_date - 30,
        end_date: end_date,
        end_meridiem: :pm
      )
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        end_meridiem: :am
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

    it "returns a new event with the earliest start date and matching start meridiem" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :pm
      )
      before = Event.new(
        type: :holiday,
        start_date: start_date - 3,
        end_date: end_date,
        start_meridiem: :am
      )
      after = Event.new(
        type: :holiday,
        start_date: start_date + 3,
        end_date: end_date,
        start_meridiem: :am
      )

      new_before = event.merge_with(before)

      expect(new_before.start_date).to eq(start_date - 3)
      expect(new_before.start_meridiem).to eq(:am)

      new_after = event.merge_with(after)

      expect(new_after.start_date).to eq(start_date)
      expect(new_after.start_meridiem).to eq(:pm)
    end

    it "returns a new event with the latest end date and matching end meridiem" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        end_meridiem: :am
      )
      before = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date - 3,
        end_meridiem: :pm
      )
      after = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date + 3,
        end_meridiem: :pm
      )

      new_before = event.merge_with(before)

      expect(new_before.end_date).to eq(end_date)
      expect(new_before.end_meridiem).to eq(:am)

      new_after = event.merge_with(after)

      expect(new_after.end_date).to eq(end_date + 3)
      expect(new_after.end_meridiem).to eq(:pm)
    end
  end

  describe "#==" do
    it "returns true when the other event has the same initializer properties as the subject" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :pm,
        end_meridiem: :am
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :pm,
        end_meridiem: :am
      )

      expect(event == other).to be(true)
    end

    it "returns false when the other event has different initializer properties from the subject" do
      event = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :pm,
        end_meridiem: :am
      )
      other = Event.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :am,
        end_meridiem: :pm
      )

      expect(event == other).to be(false)
    end
  end
end
