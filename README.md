# Scheduling event sync

At dxw we use a variety of different systems for tracking things like holiday
and sickness, support rotas, and project scheduling. This project automates
synchronising those different systems.

Within dxw this project is deployed and run on Heroku. Due to the sensitive
nature of the data, only a handful of people have access to it.

## Slack Integration

The app will post messages to a slack channel to report if it has encountered
an error. You will need to type `@Breathe Productive Sync` to add them to a new
channel.

You might need to get added to the collaborators list if you need to tweak the
bot's configuration:
https://app.slack.com/app-settings/T025PM7N0/A04U1KEJFKR/collaborators

## Manual usage

Normally you should be running this on a schedule eg on Heroku, but in case you
need to run a task manually:

1. Install the dependencies via Bundler:

   ```
   $ bundle install
   ```

2. Set up your environment variables by copying `.env.example` to `.env` and
   filling in the blanks.

### Sync BreatheHR to Productive

```
$ bundle exec rake breathe:to_productive
```

Note that this is a destructive operation. It works by looking at the current
state of the managed events in BreatheHR and updates Productive to match them by
removing any existing events in Productive that don't exist in BreatheHR, and
creating new events when they exist in BreatheHR but not Productive.

#### Changing the start date

By default, the sync task considers all events that intersect with the last 90
days. If you'd like to specify a different start date, do so by passing an
argument into the task.

```
$ bundle exec rake 'breathe:to_productive[2020-01-01]'
```

#### Specifying the accounts to synchronise

By default, the task runs for all the people records in BreatheHR. If you want
to sync specific people's records, do so by passing an EMAILS environment
variable to the task, containing the comma-separated emails.

```
$ bundle exec rake breathe:to_productive EMAILS=someone@dxw.com,sometwo@dxw.com
```

## Developing

Running the tests:

```
$ bundle exec rspec lib
```

## Debugging

Sometimes the synchronisation can go wrong, and we need to investigate why.
Very few people have API access to BreatheHR, and those people tend to have very
little time. In order to make the most out of their limited time, we have a couple of
tasks that make it easier to work with the data.

### Exporting data from BreatheHR

Also known as a data dump. This tasks exports the event data from BreatheHR, so whoever
is debugging the app can request it from a person with access and work off the outputted
files.

The task takes as arguments a list of emails (separated with **semicolons**)
and (optionally) the earliest date to look up events from in YYYY-MM-DD format.

Example usage:

```
$ bundle exec rake breathe:data_dump["example1@example.org;example2@example.org","2022-07-01"]
```

Note: for some shells, such as zsh, you might have to escape the square brackets, e.g.

```
$ bundle exec rake breathe:data_dump\["example1@example.org;example2@example.org","2022-07-01"\]
```

If no emails are given, it will export data for all people records in Breathe, and if no
starting date is given a default date will be used (currently 90 days before the current
date).

### Executing a dry run of synchronising data from files into Productive

Requires:

- Productive API credentials (read access is sufficient)
- Data dumps in the format produced by the previous task to be present in the local folder
`tmp/data/breathe/`

Example usage:

```
$ bundle exec rake breathe:to_productive_from_dump
```
