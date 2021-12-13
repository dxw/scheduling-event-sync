require_relative "../../lib/productive_client"
require_relative "../spec_helper"

RSpec.describe ProductiveClient do
  let(:productive_events) do
    [
      double(Productive::Event, id: 43368, name: "Holiday"),
      double(Productive::Event, id: 12344, name: "Something else"),
      double(Productive::Event, id: 33455, name: "Training")
    ]
  end

  let(:productive_bookings) do
    [
      FactoryBot.build(:booking, person: person1),
      FactoryBot.build(:booking, person: person2),
      FactoryBot.build(:booking, person: person1)
    ]
  end

  let(:person1) { FactoryBot.build(:person) }
  let(:person2) { FactoryBot.build(:person) }

  let(:productive_people) do
    [
      person1,
      person2
    ]
  end

  let(:productive_salaries) do
    [
      FactoryBot.build(:salary, person: person1),
      FactoryBot.build(:salary, person: person2)
    ]
  end

  before do
    allow(Productive::Event).to receive(:all).and_return(productive_events)
    allow(Productive::Person).to receive(:where).and_return(productive_people)
    allow(Productive::Salary).to receive_message_chain(:where, :all).and_return(productive_salaries)
  end

  describe "#event_types" do
    it "returns a hash of event types" do
      expect(described_class.event_types).to eq({"Holiday"=>43368, "Something else"=>12344, "Training"=>33455})
    end
  end

  describe "#events" do
    before do
      allow(described_class).to receive(:bookings).and_return(productive_bookings)
    end

    it "returns a hash of events" do
      expect(described_class.events(after: Date.new(2000, 1, 1))).to eq({})
    end
  end
end
