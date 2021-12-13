module ServiceStubs
  def stub_productive_event(id)
    url = "https://api.productive.io/api/v2/events/#{id}"
    body = JSON.parse(File.read(File.join("spec", "fixtures", "productive", "event.json"))).to_json
    stub_request(:get, url)
      .to_return(
        status: 200,
        body: body,
        headers: {
          "Content-Type" => "application/json"
        }
      )
  end

  def stub_productive_events
    url = "https://api.productive.io/api/v2/events/"
    body = JSON.parse(File.read(File.join("spec", "fixtures", "productive", "events.json"))).to_json
    stub_request(:get, url)
      .to_return(
        status: 200,
        body: body,
        headers: {
          "Content-Type" => "application/json"
        }
      )
  end

  def stub_booking_create(employee:, start_date:, end_date:, time: 420)
    stub_request(:post, "https://api.productive.io/api/v2/bookings")
      .with(
        body: {
          "data" => {
            "type" => "bookings",
            "relationships" => {
              "person" => {
                "data" => {
                  "type" => "people",
                  "id" => employee.productive_id
                }
              },
              "event" => {
                "data" => {
                  "type" => "events",
                  "id" => BreatheToProductive::HOLIDAY_EVENT_ID.to_s
                }
              }
            },
            "attributes" => {
              "started_on" => start_date.to_s,
              "ended_on" => end_date.to_s,
              "time" => time
            }
          }
        }.to_json
      ).to_return(status: 200, body: "", headers: {})
  end

  def stub_booking_delete(id)
    stub_request(:delete, "https://api.productive.io/api/v2/bookings/#{id}")
      .to_return(status: 204, body: "", headers: {})
  end
end

RSpec.configure do |config|
  config.include ServiceStubs
end
