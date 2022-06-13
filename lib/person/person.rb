require_relative "../breathe_client"
require_relative "../productive_client"

class Person
  class << self
    def all_from_breathe
      BreatheClient.employees
        .map { |employee|
          id = employee[:id]
          email = employee[:email]

          emails = email_aliases.find { |emails| emails.include?(email) }
          emails = [email] if emails.nil?

          Person.new(emails: emails, breathe_id: id)
        }
        .compact
    end
  end

  attr_reader :emails, :breathe_id, :productive_id

  def initialize(emails:, breathe_id: nil, productive_id: nil)
    @emails = emails
    @breathe_id = breathe_id
    @productive_id = productive_id
  end

  def label
    emails.first
  end

  def sync_breathe_to_productive(after:, breathe_events: nil)
    unless fetch_productive_attributes
      puts "#{label}: no match on Productive"
      return
    end

    puts "#{label}: finding changes"

    breathe_events = breathe_events(after: after) unless breathe_events
    productive_events = productive_events(after: after)

    changeset = {
      removed: productive_events,
      added: breathe_events.compress.split_half_days
    }

    ProductiveClient.update_events_for(self, changeset)

    puts "#{label}: done"
  end

  def breathe_data(after:)
    {
      emails: emails,
      earliest_date: after.strftime("%F"),
      events: breathe_events(after: after).as_json
    }
  end

  private

  attr_writer :breathe_id, :productive_id

  def fetch_productive_attributes
    return true unless productive_id.nil?

    productive_person = ProductiveClient.person(emails: emails)

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
