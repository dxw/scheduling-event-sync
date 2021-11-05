require_relative "./absence"

class AbsenceCollection
  attr_reader :absences

  def initialize(absences)
    @absences = absences.sort_by(&:start_date)
  end

  def compress!
    self.absences = absences
      .group_by(&:type)
      .flat_map { |(type, group)|
        group.each_with_object([]) { |absence, list|
          if list.last&.mergeable_with?(absence)
            list[list.length - 1] = absence.merge_with(list.last)
          else
            list << absence
          end
        }
      }
      .sort_by(&:start_date)

    self
  end

  private

  attr_writer :absences
end
