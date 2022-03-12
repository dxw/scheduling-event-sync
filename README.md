# Scheduling event sync

At dxw we use a variety of different systems for tracking things like holiday
and sickness, support rotas, and project scheduling. This project automates
synchronising those different systems.

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
