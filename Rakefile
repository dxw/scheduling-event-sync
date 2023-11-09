require "dotenv"
Dotenv.load

require_relative "lib/event/event"
require_relative "lib/event/event_collection"
require_relative "lib/person/person"
require_relative "lib/breathe_client"
require_relative "lib/productive_client"

require "rollbar"

Rollbar.configure do |config|
  config.access_token = ENV.fetch("ROLLBAR_ACCESS_TOKEN")
  config.environment = ENV.fetch("ROLLBAR_ENVIRONMENT")
end

def to_bool(arg)
  return true if arg == true || arg =~ (/(true|t|yes|y|1)$/i)
  return false if arg == false || arg =~ (/(false|f|no|n|0)$/i)

  raise ArgumentError.new("Unable to convert value to boolean: \"#{arg}\"")
end

def email_aliases
  ENV.fetch("EMAIL_ALIASES", "")
    .strip
    .split("\n")
    .map { |line| line.strip.split(/\s*[,;]\s*/) }
end

namespace :productive do
  desc "List all event types on Productive"
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
  task :to_productive, [:earliest_date] do |t, args|
    args.with_defaults(earliest_date: (Date.today - 90).strftime("%F"))

    dry_run = to_bool(ENV.fetch("SYNC_DRY_RUN", true))

    if dry_run
      puts "[INFO] Doing a dry run!"
      puts "[INFO] Temporarily set the environment variable `SYNC_DRY_RUN` to a falsy value to make\nreal changes to Productive"
    end

    earliest_date = Date.parse(args[:earliest_date]).strftime("%F")
    puts "[INFO] Syncing events on or after #{earliest_date}"

    BreatheClient.configure(
      api_key: ENV.fetch("BREATHE_API_KEY"),
      event_types: {
        holiday: ENV.fetch("BREATHE_HOLIDAY_EVENT_TYPE"),
        other_leave: ENV.fetch("BREATHE_OTHER_LEAVE_EVENT_TYPE")
      },
      event_reason_types: {
        ignored: ENV.fetch("BREATHE_IGNORED_EVENT_REASON_TYPES").split(",")
      },
      email_aliases: email_aliases
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

    people_to_sync = Person.all_from_breathe
    emails = ENV.fetch("EMAILS", "").split(",").map(&:strip)

    if emails.any?
      people_to_sync = people_to_sync.select { |person| (person.emails & emails).any? }
      puts "[INFO] Syncing events for #{people_to_sync.map(&:label).join(", ")}"
    end

    people_to_sync.each { |person| person.sync_breathe_to_productive(after: earliest_date) }
  rescue => e
    Rollbar.error(e)
    raise
  end

  desc "Obtain the event data from BreatheHR for all or specified employees"
  task :data_dump, [:emails, :earliest_date] do |t, args|
    args.with_defaults(emails: "", earliest_date: (Date.today - 90).strftime("%F"))

    earliest_date = Date.parse(args[:earliest_date]).strftime("%F")
    puts "Fetching events on or after #{earliest_date}"

    emails = args[:emails].split(";").map(&:strip)

    BreatheClient.configure(
      api_key: ENV.fetch("BREATHE_API_KEY"),
      event_types: {
        holiday: ENV.fetch("BREATHE_HOLIDAY_EVENT_TYPE"),
        other_leave: ENV.fetch("BREATHE_OTHER_LEAVE_EVENT_TYPE")
      },
      event_reason_types: {
        ignored: ENV.fetch("BREATHE_IGNORED_EVENT_REASON_TYPES").split(",")
      },
      email_aliases: email_aliases
    )

    people = Person.all_from_breathe
    people = people.select { |person| (person.emails & emails).any? } if emails.any?

    require "fileutils"
    FileUtils.mkdir_p "tmp/data/breathe"

    people.map do |person|
      person_data = person.breathe_data(after: earliest_date)
      File.write("tmp/data/breathe/#{person.emails.first}.json", JSON.generate(person_data))
    end
  end

  desc "Do a verbose dry run from files of BreatheHR data"
  task :to_productive_from_dump do
    puts "Doing a dry run!"
    puts
    puts "This task always does a dry run."
    puts "You must use the Breathe API to make real changes:"
    puts
    puts "$ bundle exec rake breathe:to_productive"
    puts

    ProductiveClient.configure(
      account_id: ENV.fetch("PRODUCTIVE_ACCOUNT_ID"),
      api_key: ENV.fetch("PRODUCTIVE_API_KEY"),
      event_ids: {
        holiday: ENV.fetch("PRODUCTIVE_HOLIDAY_EVENT_ID"),
        sickness: ENV.fetch("PRODUCTIVE_SICKNESS_EVENT_ID"),
        other_leave: ENV.fetch("PRODUCTIVE_OTHER_LEAVE_EVENT_ID")
      },
      dry_run: true
    )

    filenames = Dir.glob("tmp/data/breathe/*.json")
    puts "Using data from #{filenames}"

    filenames.each do |filename|
      person_data = JSON.parse(File.read(filename))

      person = Person.new(emails: person_data["emails"])
      breathe_events = EventCollection.from_array(person_data["events"])

      person.sync_breathe_to_productive(
        after: person_data["earliest_date"],
        breathe_events: breathe_events
      )
    end
  end
end
