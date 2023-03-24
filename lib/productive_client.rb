require "active_support/all"
require "memo_wise"
require "productive"

class ProductiveClient
  class << self
    prepend MemoWise

    DEFAULT_WORKING_HOURS = [
      7,
      7,
      7,
      7,
      7,
      0,
      0
    ].freeze

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

    def event_types
      Productive::Event.all.map.each_with_object({}) { |event, hash|
        hash[event.name] = event.id
      }
    end
    memo_wise :event_types

    def events(person:, after:)
      events = bookings(person_id: person.productive_id, after: after)
        .map { |booking|
          # Not sure why there might be nil time bookings, but there do seem
          # to be.
          next if booking.time.nil?

          start_date = booking.started_on.to_date
          end_date = booking.ended_on.to_date

          half_day = if start_date == end_date
            working_time = daily_working_minutes(
              person_id: person.productive_id,
              after: start_date,
              before: end_date
            )

            booking.time <= working_time / 2
          else
            false
          end

          Event.new(
            type: event_ids.key(booking.event.id),
            start_date: start_date,
            end_date: end_date,
            half_day_at_start: half_day,
            half_day_at_end: half_day
          )
        }
        .compact

      EventCollection.new(events)
    end
    memo_wise :events

    def update_events_for(person, changeset)
      changeset[:removed].events.each { |event|
        event_id = event_ids[event.type]

        matching_bookings = Productive::Booking
          .where(
            event_id: event_id,
            after: event.start_date,
            before: event.end_date
          )
          .all
          .select { |booking|
            booking.started_on.to_date == event.start_date &&
              booking.ended_on.to_date == event.end_date
          }

        matching_bookings.each { |booking|
          puts "[INFO] #{person.label}: remove #{event_ids.key(booking.event.id)} #{booking.started_on.to_date} - #{booking.ended_on.to_date} (#{booking.time.to_f / 60} hours / day)"

          booking.destroy unless dry_run
        }
      }

      changeset[:added].events.each { |event|
        event_id = event_ids[event.type]

        working_time = daily_working_minutes(
          person_id: person.productive_id,
          after: event.start_date,
          before: event.end_date
        )

        time =
          event.half_day_at_start || event.half_day_at_end ?
          working_time / 2 :
          working_time

        puts "[INFO] #{person.label}: create #{event.type} #{event.start_date} - #{event.end_date} (#{time.to_f / 60} hours / day)"

        unless dry_run
          response = Productive::Booking.create(
            person_id: person.productive_id,
            event_id: event_id,
            started_on: event.start_date,
            ended_on: event.end_date,
            time: time
          )
          if response.nil? || response.attributes["id"].nil?
            puts "[ERROR] #{person.label}: Productive booking #{event.type} #{event.start_date} - #{event.end_date} not created"
          end
        end
      }
    end

    def person(emails:)
      Productive::Person.where(email: emails).first
    end
    memo_wise :person

    private

    attr_reader :event_ids

    def bookings(person_id:, after:)
      Productive::Booking
        .where(
          person_id: person_id,
          event_id: event_ids.values,
          after: after
        )
        .all
    end
    memo_wise :bookings

    def salaries(person_id:, after:, before:)
      Productive::Salary
        .where(
          person_id: person_id,
          after: after,
          before: before
        )
        .all
    end
    memo_wise :salaries

    def working_hours(person_id:, after:, before:)
      salary = salaries(person_id: person_id, after: after, before: before)
        .find { |salary|
          next if salary.nil?

          (0..7).find { |index|
            salary.working_hours[index] > 0
          }
        }

      return DEFAULT_WORKING_HOURS if salary.nil?

      salary.working_hours
    end
    memo_wise :working_hours

    def daily_working_minutes(person_id:, after:, before:)
      hours = working_hours(person_id: person_id, after: after, before: before)

      return if hours.nil?

      hours.max * 60
    end
    memo_wise :daily_working_minutes
  end
end
