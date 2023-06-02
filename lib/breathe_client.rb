require "active_support/all"
require "breathe"
require "memo_wise"

class BreatheClient
  class << self
    prepend MemoWise

    def configure(api_key:, event_types:, event_reason_types:, email_aliases:)
      reset_memo_wise

      @client = Breathe::Client.new(api_key: api_key, auto_paginate: true)
      @event_types = event_types
      @event_reason_types = event_reason_types
      @email_aliases = email_aliases
    end

    def events(person:, after:)
      absence = absence_events(person: person, after: after)
      sickness = sickness_events(person: person, after: after)
      training = training_events(person: person, after: after)

      absence + sickness + training
    end
    memo_wise :events

    def absence_events(person:, after:)
      events = absences(employee_id: person.breathe_id, after: after)
        .map { |absence|
          leave_reason = absence.leave_reason&.name
          leave_reason_type = event_reason_types
            .keys
            .find { |reason|
              event_reason_types[reason].include?(leave_reason)
            }
          next if leave_reason_type == :ignored

          type = event_types.key(absence.type)
          type = :other_leave if type.nil?

          start_date = absence.start_date.to_date
          end_date = absence.end_date.to_date
          half_day_at_start = absence.half_start
          half_day_at_end = absence.half_end

          if end_date < Date.parse(after)
            puts "[DEBUG] #{person.label}: Skipping absence with end date #{end_date.strftime("%F")} older than the requested earliest date #{after}"
            next
          end

          Event.new(
            type: type,
            start_date: start_date,
            end_date: end_date,
            half_day_at_start: half_day_at_start,
            half_day_at_end: half_day_at_end
          )
        }
        .compact

      EventCollection.new(events)
    end
    memo_wise :absence_events

    def sickness_events(person:, after:)
      events = sicknesses(employee_id: person.breathe_id, after: after)
        .map { |sickness|
          start_date = sickness[:start_date].to_date
          end_date = sickness[:end_date]&.to_date || Date.today
          half_day_at_start = sickness[:half_start]
          half_day_at_end = sickness[:half_end]

          if end_date < Date.parse(after)
            puts "[DEBUG] #{person.label}: Skipping sickness with end date #{end_date.strftime("%F")} older than the requested earliest date #{after}"
            next
          end

          Event.new(
            type: :sickness,
            start_date: start_date,
            end_date: end_date,
            half_day_at_start: half_day_at_start,
            half_day_at_end: half_day_at_end
          )
        }
        .compact

      EventCollection.new(events)
    end
    memo_wise :sickness_events

    def training_events(person:, after:)
      events = trainings(employee_id: person.breathe_id, after: after)
        .map { |training|
          start_date = training[:start_on]&.to_date

          if start_date.nil?
            puts "[DEBUG] #{person.label}: Skipping training with nil start_date"
            next
          end

          end_date = training[:end_on]&.to_date

          if end_date.nil?
            puts "[DEBUG] #{person.label}: Skipping training with nil end_date"
            next
          end

          if end_date < Date.parse(after)
            puts "[DEBUG] #{person.label}: Skipping training with end date #{end_date.strftime("%F")} older than the requested earliest date #{after}"
            next
          end

          half_day_at_start = training[:half_day] && training[:half_day_am_pm].to_s.downcase == "am"
          half_day_at_end = training[:half_day] && training[:half_day_am_pm].to_s.downcase == "pm"

          Event.new(
            type: :other_leave,
            start_date: start_date,
            end_date: end_date,
            half_day_at_start: half_day_at_start,
            half_day_at_end: half_day_at_end
          )
        }
        .compact

      EventCollection.new(events)
    end
    memo_wise :training_events

    def employees
      client
        .employees
        .list
        .response
        .data[:employees]
    rescue => error
      raise unless rate_limited?(error)

      await_rate_limit_reset

      employees
    end
    memo_wise :employees

    private

    SECONDS_FOR_RATE_LIMIT_RESET = 60

    attr_reader :client, :event_types, :event_reason_types, :email_aliases

    def absences(employee_id:, after:)
      client
        .absences
        .list(
          employee_id: employee_id,
          after: after,
          exclude_cancelled_absences: true
        )
        .response
        .data[:absences]
    rescue => error
      raise unless rate_limited?(error)

      await_rate_limit_reset

      absences(employee_id: employee_id, after: after)
    end
    memo_wise :absences

    def sicknesses(employee_id:, after:)
      client
        .sicknesses
        .list(
          employee_id: employee_id,
          after: after,
          exclude_cancelled_sicknesses: true
        )
        .response
        .data[:sicknesses]
    rescue => error
      raise unless rate_limited?(error)

      await_rate_limit_reset

      sicknesses(employee_id: employee_id, after: after)
    end
    memo_wise :sicknesses

    def trainings(employee_id:, after:)
      client
        .employee_training_courses
        .list(
          employee_id: employee_id,
          after: after,
          exclude_cancelled_employee_training_courses: true
        )
        .response
        .data[:employee_training_courses]
    rescue => error
      raise unless rate_limited?(error)

      await_rate_limit_reset

      trainings(employee_id: employee_id, after: after)
    end
    memo_wise :trainings

    def rate_limited?(error)
      (
        error.instance_of?(Breathe::UnknownError) &&
        client.last_response.data[:error][:type] == "Rate Limit Reached"
      ) || (
        error.instance_of?(TypeError) &&
        error.message == "no implicit conversion of nil into Array"
      )
    end

    def await_rate_limit_reset
      puts "Waiting #{SECONDS_FOR_RATE_LIMIT_RESET} seconds due to rate limiting by Breathe"
      sleep SECONDS_FOR_RATE_LIMIT_RESET
    end
  end
end
