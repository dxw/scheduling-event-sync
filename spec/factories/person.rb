FactoryBot.define do
  factory :person, class: Productive::Person do
    id { rand(10000) }
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.first_name }

    transient do
      json {
        {
          "id": id,
          "type": "people",
          "attributes": {
            "first_name": FFaker::Name.first_name,
            "last_name": FFaker::Name.last_name,
            "email": email,
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
          },
          "relationships": {
            "organization": {"data": {"type": "organizations", "id": 15071}},
            "company": {"data": {"type": "companies", "id": "180872"}},
            "subsidiary": {"data": {"type": "subsidiaries", "id": "14723"}}
          }
        }
      }
    end

    skip_create

    after(:create) do |absence, evaluator|
      @json ||= {
        "data" => []
      }
      @json["data"] << evaluator.json

      url = "https://api.productive.io/api/v2/people"
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
