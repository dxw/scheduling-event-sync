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
            start_half_day = absence.half_start
            end_half_day = absence.half_end

            Event.new(
              type: type,
              start_date: start_date,
              end_date: end_date,
              start_half_day: start_half_day,
              end_half_day: end_half_day
            )
          }
          .compact

        hash[email] = EventCollection.new(events)
      }
    end
    memo_wise :events

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
  end
end
