require "dotenv"
Dotenv.load

require_relative "./lib/event/event"
require_relative "./lib/event/event_collection"
require_relative "./lib/breathe_client"
require_relative "./lib/productive_client"

def to_bool(arg)
  return true if arg == true || arg =~ (/(true|t|yes|y|1)$/i)
  return false if arg == false || arg =~ (/(false|f|no|n|0)$/i)

  raise ArgumentError.new("Unable to convert value to boolean: \"#{arg}\"")
end

namespace :productive do
  desc "Compress all compressible managed events on Productive"
  task :compress, [:dry_run] do |t, args|
    args.with_defaults(dry_run: true)

    dry_run = to_bool(args[:dry_run])

    puts "Doing a dry run!" if dry_run

    ProductiveClient.configure(
      account_id: ENV.fetch("PRODUCTIVE_ACCOUNT_ID"),
      api_key: ENV.fetch("PRODUCTIVE_API_KEY"),
      event_ids: {
        holiday: ENV.fetch("PRODUCTIVE_HOLIDAY_EVENT_ID"),
        sickness: ENV.fetch("PRODUCTIVE_SICKNESS_EVENT_ID"),
        other_leave: ENV.fetch("PRODUCTIVE_OTHER_LEAVE_EVENT_ID")
      },
      dry_run: dry_run
    )

    productive_events = ProductiveClient.events(
      after: Date.today - 90
    )

    productive_events.each_pair { |email, events|
      puts "#{email}: finding changes"

      changeset = events.all_changes_from(
        events,
        compress: true,
        split_half_days: true
      )

      ProductiveClient.update_events_for(email, changeset)

      puts "#{email}: done"
    }
  end

  task :list_event_types do
    ProductiveClient.configure(
      account_id: ENV.fetch("PRODUCTIVE_ACCOUNT_ID"),
      api_key: ENV.fetch("PRODUCTIVE_API_KEY"),
      event_ids: {}
    )

    puts ProductiveClient.event_types
  end
end

namespace :breathe do
  desc "Update all managed events on Productive to match Breathe"
  task :to_productive, [:dry_run] do |t, args|
    args.with_defaults(dry_run: true)

    dry_run = to_bool(args[:dry_run])

    puts "Doing a dry run!" if dry_run

    BreatheClient.configure(
      api_key: ENV.fetch("BREATHE_API_KEY"),
      event_types: {
        holiday: ENV.fetch("BREATHE_HOLIDAY_EVENT_TYPE"),
        other_leave: ENV.fetch("BREATHE_OTHER_LEAVE_EVENT_TYPE")
      },
      event_reason_types: {
        ignored: ENV.fetch("BREATHE_IGNORED_EVENT_REASON_TYPES").split(",")
      }
    )

    ProductiveClient.configure(
      account_id: ENV.fetch("PRODUCTIVE_ACCOUNT_ID"),
      api_key: ENV.fetch("PRODUCTIVE_API_KEY"),
      event_ids: {
        holiday: ENV.fetch("PRODUCTIVE_HOLIDAY_EVENT_ID"),
        sickness: ENV.fetch("PRODUCTIVE_SICKNESS_EVENT_ID"),
        other_leave: ENV.fetch("PRODUCTIVE_OTHER_LEAVE_EVENT_ID")
      },
      dry_run: dry_run
    )

    date = Date.today - 90

    breathe_events = BreatheClient.events(
      after: date
    )

    productive_events = ProductiveClient.events(
      after: date
    )

    breathe_events.each_pair { |email, events|
      other_events = productive_events[email]

      if other_events.nil?
        puts "#{email}: no match"
        next
      end

      puts "#{email}: finding changes"

      changeset = events.all_changes_from(
        other_events,
        compress: true,
        split_half_days: true
      )

      ProductiveClient.update_events_for(email, changeset)

      puts "#{email}: done"
    }
  end
end
