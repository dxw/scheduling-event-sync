FactoryBot.define do
  factory :booking, class: Productive::Booking do
    id { rand(10000) }
    hours { 7 }
    time { 420 }
    started_on { Date.today }
    ended_on { Date.today }
    note { nil }
    total_time { time * total_working_days }
    total_working_days { 1 }
    percentage { nil }
    created_at { DateTime.now }
    updated_at { DateTime.now }
    people_custom_fields { nil }
    approved { false }
    approved_at { nil }
    rejected { false }
    rejected_reason { nil }
    rejected_at { nil }
    canceled { false }
    canceled_at { nil }
    person { build(:person) }

    transient do
      included {
        {
          "id": person.id,
          "type": "people",
          "attributes": {
            "first_name": person.first_name,
            "last_name": person.last_name,
            "email": person.email,
            "title": nil,
            "joined_at": "2021-04-16T17:39:56.000+02:00",
            "last_seen_at": "2021-04-30T11:36:23.727+02:00",
            "deactivated_at": nil,
            "archived_at": nil,
            "role_id": 12,
            "invited_at": "2021-04-16T17:06:30.000+02:00",
            "is_user": true,
            "user_id": id,
            "tag_list": [],
            "avatar_url": nil,
            "virtual": false,
            "custom_fields": nil,
            "autotracking": false,
            "created_at": "2021-04-16T17:06:29.711+02:00",
            "placeholder": false,
            "color_id": nil,
            "private_custom_reports_used": 0,
            "contact": {},
            "sample_data": nil
          }
        }
      }
      json {
        {
          "id": id,
          "type": "bookings",
          "attributes": {
            "hours": hours,
            "time": time,
            "started_on": started_on,
            "ended_on": ended_on,
            "note": note,
            "total_time": total_time,
            "total_working_days": total_working_days,
            "percentage": percentage,
            "created_at": created_at,
            "updated_at": updated_at,
            "people_custom_fields": people_custom_fields,
            "approved": approved,
            "approved_at": approved_at,
            "rejected": rejected,
            "rejected_reason": rejected_reason,
            "rejected_at": rejected_at,
            "canceled": canceled,
            "canceled_at": canceled_at
          },
          "relationships": {
            "person": {
              "data": {
                "type": "people",
                "id": person.id
              }
            }
          }
        }
      }
    end

    skip_create

    after(:create) do |absence, evaluator|
      @json ||= {
        "data" => [],
        "included" => []
      }
      @json["data"] << evaluator.json
      @json["included"] << evaluator.included

      url = "https://api.productive.io/api/v2/bookings?filter%5Bafter%5D=#{Date.today}&filter%5Bevent_id%5D=#{BreatheToProductive::HOLIDAY_EVENT_ID}"
      WebMock.stub_request(:get, url)
        .to_return(
          status: 200,
          body: @json.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
    end
  end
end
