require_relative "./absence"

class AbsenceCollection
  attr_reader :absences

  def initialize(absences)
    @absences = absences.sort_by(&:start_date)
  end

  def all_changes_from(other)
    our_unshared_absences = absences.reject { |absence|
      other.absences.include?(absence)
    }
    their_unshared_absences = other.absences.reject { |absence|
      absences.include?(absence)
    }

    {
      added: AbsenceCollection.new(our_unshared_absences),
      removed: AbsenceCollection.new(their_unshared_absences)
    }
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
