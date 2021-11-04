require "date"
require_relative "./absence"

RSpec.describe Absence do
  let(:start_date) { Date.new(2000, 1, 1) }
  let(:end_date) { Date.new(2000, 2, 1) }

  describe ".new" do
    it "rejects an invalid type" do
      expect {
        Absence.new(
          type: :invalid,
          start_date: start_date,
          end_date: end_date
        )
      }.to raise_error("invalid is not a recognized absence type")
    end

    it "rejects a non-date start date" do
      expect {
        Absence.new(
          type: :holiday,
          start_date: "2000-01-01",
          end_date: end_date
        )
      }.to raise_error("2000-01-01 is not a date")
    end

    it "rejects a non-date end date" do
      expect {
        Absence.new(
          type: :holiday,
          start_date: start_date,
          end_date: "2000-02-01"
        )
      }.to raise_error("2000-02-01 is not a date")
    end

    it "rejects an end date before the start date" do
      expect {
        Absence.new(
          type: :holiday,
          start_date: start_date,
          end_date: start_date - 1
        )
      }.to raise_error("An absence cannot end before it starts")
    end

    it "rejects an end meridiem before the start meridiem when the start and end dates are the same" do
      expect {
        Absence.new(
          type: :holiday,
          start_date: start_date,
          end_date: start_date,
          start_meridiem: :pm,
          end_meridiem: :am
        )
      }.to raise_error("An absence cannot end before it starts")
    end

    it "rejects an invalid start meridiem" do
      expect {
        Absence.new(
          type: :holiday,
          start_date: start_date,
          end_date: end_date,
          start_meridiem: :invalid
        )
      }.to raise_error("invalid is not a recognized meridiem")
    end

    it "rejects an invalid end meridiem" do
      expect {
        Absence.new(
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
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(absence.type).to eq(:holiday)
    end

    it "is read-only" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(absence).not_to respond_to(:type=)
    end
  end

  describe "#start_date" do
    it "returns the initial start date" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(absence.start_date).to eq(start_date)
    end

    it "is read-only" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(absence).not_to respond_to(:start_date=)
    end
  end

  describe "#end_date" do
    it "returns the initial end date" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(absence.end_date).to eq(end_date)
    end

    it "is read-only" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(absence).not_to respond_to(:end_date=)
    end
  end

  describe "#start_meridiem" do
    it "returns the initial start meridiem" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :pm
      )

      expect(absence.start_meridiem).to eq(:pm)
    end

    it "defaults to AM" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(absence.start_meridiem).to eq(:am)
    end

    it "is read-only" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        start_meridiem: :pm
      )

      expect(absence).not_to respond_to(:start_meridiem=)
    end
  end

  describe "#end_meridiem" do
    it "returns the initial end meridiem" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        end_meridiem: :am
      )

      expect(absence.end_meridiem).to eq(:am)
    end

    it "is read-only" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date,
        end_meridiem: :am
      )

      expect(absence).not_to respond_to(:end_meridiem=)
    end
  end

  describe "#matches_type?" do
    it "returns true when the other absence is of the same type" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )

      expect(absence.matches_type?(other)).to be(true)
    end

    it "returns false when the other absence is of the a different type" do
      absence = Absence.new(
        type: :holiday,
        start_date: start_date,
        end_date: end_date
      )
      other = Absence.new(
        type: :sickness,
        start_date: start_date,
        end_date: end_date
      )

      expect(absence.matches_type?(other)).to be(false)
    end
  end
end
