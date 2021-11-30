require "active_support/all"
require "memo_wise"
require "productive"

class ProductiveClient
  class << self
    prepend MemoWise

    DEFAULT_WORKING_HOURS = 7

    attr_reader :dry_run

    def configure(account_id:, api_key:, event_ids:, dry_run: true)
      reset_memo_wise

      Productive.configure do |config|
        config.account_id = account_id
        config.api_key = api_key
      end

      @event_ids = event_ids
      @dry_run = dry_run
    end

    def events(after:)
      bookings_by_email = bookings(after: after).group_by { |booking|
        booking.person.email.downcase
      }

      bookings_by_email.keys.each_with_object({}) { |email, hash|
        person_id = person(email: email).id

        events = bookings_by_email[email]
          .map { |booking|
            # Not sure why there might be nil time bookings, but there do seem
            # to be.
            next if booking.time.nil?

            start_date = booking.started_on.to_date
            end_date = booking.ended_on.to_date

            half_day = if start_date == end_date
              working_hours = salary(
                person_id: person_id,
                on: start_date
              )
                .working_hours[start_date.wday - 1]
              working_minutes = (working_hours || DEFAULT_WORKING_HOURS) * 60

              booking.time <= working_minutes / 2
            else
              false
            end

            Event.new(
              type: event_ids.key(booking.event.id),
              start_date: start_date,
              end_date: end_date,
              start_half_day: half_day,
              end_half_day: half_day
            )
          }
          .compact

        hash[email] = EventCollection.new(events)
      }
    end
    memo_wise :events

    private

    attr_reader :event_ids

    def bookings(after:)
      Productive::Booking
        .where(
          event_id: event_ids.values,
          after: after
        )
        .all
    end
    memo_wise :bookings

    def person(email:)
      Productive::Person.where(email: email).first
    end
    memo_wise :person

    def salary(person_id:, on:)
      Productive::Salary
        .where(
          person_id: person_id,
          after: on,
          before: on
        )
        .first
    end
    memo_wise :salary
  end
end
