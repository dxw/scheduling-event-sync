require_relative "../breathe_client"
require_relative "../productive_client"

class Person
  class << self
    def all_from_breathe
      BreatheClient.employees
        .map { |employee|
          id = employee[:id]
          email = employee[:email]

          Person.new(email: email, breathe_id: id)
        }
        .compact
    end
  end

  attr_reader :email, :breathe_id, :productive_id

  def initialize(email:, breathe_id: nil, productive_id: nil)
    @email = email
    @breathe_id = breathe_id
    @productive_id = productive_id
  end

  def label
    email
  end

  def sync_breathe_to_productive(after:)
    unless fetch_productive_attributes
      puts "#{label}: no match on Productive"
      return
    end

    puts "#{label}: finding changes"

    breathe_events = breathe_events(after: after)
    productive_events = productive_events(after: after)

    changeset = breathe_events.all_changes_from(
      productive_events,
      compress: true,
      split_half_days: true
    )

    ProductiveClient.update_events_for(self, changeset)

    puts "#{label}: done"
  end

  private

  attr_writer :breathe_id, :productive_id

  def fetch_productive_attributes
    return true unless productive_id.nil?

    productive_person = ProductiveClient.person(email: email)

    return false if productive_person.nil?

    self.productive_id = productive_person.id

    true
  end

  def breathe_events(after:)
    BreatheClient.events(person: self, after: after)
  end

  def productive_events(after:)
    ProductiveClient.events(person: self, after: after)
  end
end
