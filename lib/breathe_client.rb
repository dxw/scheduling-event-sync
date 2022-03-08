require "active_support/all"
require "breathe"
require "memo_wise"

class BreatheClient
  class << self
    prepend MemoWise

    def configure(api_key:, event_types:, event_reason_types:)
      reset_memo_wise

      @client = Breathe::Client.new(api_key: api_key, auto_paginate: true)
      @event_types = event_types
      @event_reason_types = event_reason_types
    end

    def events(after:)
      absence = absence_events(after: after)
      sickness = sickness_events(after: after)
      training = training_events(after: after)

      emails = absence.keys | sickness.keys | training.keys

      emails.each_with_object({}) { |email, hash|
        events =
          (absence[email]&.events || []) +
          (sickness[email]&.events || []) +
          (training[email]&.events || [])

        hash[email] = EventCollection.new(events)
      }
    end
    memo_wise :events

    def absence_events(after:)
      absences_by_email = absences(after: after).group_by { |absence|
        absence.employee.email.downcase
      }

      absences_by_email.keys.each_with_object({}) { |email, hash|
        events = absences_by_email[email]
          .map { |absence|
            leave_reason = event_reason_types
              .keys
              .find { |reason|
                event_reason_types[reason].include?(absence.leave_reason&.name)
              }
            next if leave_reason == :ignored

            type = event_types.key(absence.type)
            type = :other_leave if type.nil?

            start_date = absence.start_date.to_date
            end_date = absence.end_date.to_date
            half_day_at_start = absence.half_start
            half_day_at_end = absence.half_end

            Event.new(
              type: type,
              start_date: start_date,
              end_date: end_date,
              half_day_at_start: half_day_at_start,
              half_day_at_end: half_day_at_end
            )
          }
          .compact

        hash[email] = EventCollection.new(events)
      }
    end
    memo_wise :absence_events

    def sickness_events(after:)
      sicknesses_by_email = sicknesses(after: after).group_by { |sickness|
        id = sickness[:employee][:id]
        e = employees.find { |employee| employee[:id] == id }

        e[:email]
      }

      sicknesses_by_email.keys.each_with_object({}) { |email, hash|
        events = sicknesses_by_email[email]
          .map { |sickness|
            start_date = sickness[:start_date].to_date
            end_date = sickness[:end_date]&.to_date || Date.today
            half_day_at_start = sickness[:half_start]
            half_day_at_end = sickness[:half_end]

            Event.new(
              type: :sickness,
              start_date: start_date,
              end_date: end_date,
              half_day_at_start: half_day_at_start,
              half_day_at_end: half_day_at_end
            )
          }
          .compact

        hash[email] = EventCollection.new(events)
      }
    end
    memo_wise :sickness_events

    def training_events(after:)
      trainings_by_email = trainings(after: after).group_by { |training|
        id = training[:employee][:id]
        e = employees.find { |employee| employee[:id] == id }

        e[:email]
      }

      trainings_by_email.keys.each_with_object({}) { |email, hash|
        events = trainings_by_email[email]
          .map { |training|
            start_date = training[:start_date]&.to_date

            next if start_date.nil?

            end_date = training[:end_date]&.to_date

            next if end_date.nil?

            half_day_at_start = training[:half_start]
            half_day_at_end = training[:half_end]

            Event.new(
              type: :other_leave,
              start_date: start_date,
              end_date: end_date,
              half_day_at_start: half_day_at_start,
              half_day_at_end: half_day_at_end
            )
          }
          .compact

        hash[email] = EventCollection.new(events)
      }
    end
    memo_wise :training_events

    private

    attr_reader :client, :event_types, :event_reason_types

    def absences(after:)
      client
        .absences
        .list(start_date: after, exclude_cancelled_absences: true)
        .response
        .data[:absences]
    end
    memo_wise :absences

    def sicknesses(after:)
      client
        .sicknesses
        .list(
          start_date: after,
          exclude_cancelled_sicknesses: true
        )
        .response
        .data
        .to_h[:sicknesses]
    end
    memo_wise :sicknesses

    def trainings(after:)
      client
        .employee_training_courses
        .list(
          start_date: after,
          exclude_cancelled_employee_training_courses: true
        )
        .response
        .data
        .to_h[:employee_training_courses]
    end
    memo_wise :trainings

    def employees
      client
        .employees
        .list
        .response
        .data[:employees]
    end
    memo_wise :employees
  end
end
