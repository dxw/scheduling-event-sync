require "date"
require_relative "./absence"
require_relative "./absence_collection"

RSpec.describe AbsenceCollection do
  describe "#absences" do
    it "returns the absences, sorted by start date" do
      earliest = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1)
      )
      middle = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 10),
        end_date: Date.new(2000, 1, 14)
      )
      latest = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 2, 10),
        end_date: Date.new(2000, 3, 1)
      )

      collection = AbsenceCollection.new([middle, latest, earliest])

      expect(collection.absences).to eq([earliest, middle, latest])
    end

    it "is read-only" do
      collection = AbsenceCollection.new([])

      expect(collection).not_to respond_to(:absences=)
    end
  end

  describe "#compress!" do
    it "modifies wrapped absences array to merge all mergeable items" do
      mergeable_holiday_1a = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 1),
        end_date: Date.new(2000, 2, 1)
      )
      mergeable_holiday_1b = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 1, 10),
        end_date: Date.new(2000, 1, 14)
      )
      mergeable_holiday_2a = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 3, 1),
        end_date: Date.new(2000, 4, 1)
      )
      mergeable_holiday_2b = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 4, 1),
        end_date: Date.new(2000, 8, 1)
      )
      mergeable_holiday_2c = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 5, 2),
        end_date: Date.new(2000, 6, 1)
      )
      mergeable_holiday_2d = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 3, 2),
        end_date: Date.new(2000, 7, 1)
      )
      solo_holiday = Absence.new(
        type: :holiday,
        start_date: Date.new(2000, 8, 3),
        end_date: Date.new(2000, 9, 1)
      )
      unmergeable_sickness = Absence.new(
        type: :sickness,
        start_date: Date.new(2000, 1, 10),
        end_date: Date.new(2000, 5, 1)
      )

      collection = AbsenceCollection.new([
        mergeable_holiday_1a,
        mergeable_holiday_1b,
        mergeable_holiday_2a,
        mergeable_holiday_2b,
        mergeable_holiday_2c,
        mergeable_holiday_2d,
        solo_holiday,
        unmergeable_sickness
      ])

      collection.compress!

      expect(collection.absences).to eq([
        mergeable_holiday_1a,
        unmergeable_sickness,
        Absence.new(
          type: :holiday,
          start_date: Date.new(2000, 3, 1),
          end_date: Date.new(2000, 8, 1)
        ),
        solo_holiday
      ])
    end

    it "returns the subject" do
      collection = AbsenceCollection.new([])

      expect(collection.compress!).to be(collection)
    end
  end
end
