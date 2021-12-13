FactoryBot.define do
  factory :salary, class: Productive::Salary do
    person { build(:person) }
    after { Date.new(2019, 1, 1) }
    before { Date.new(2010, 1, 1) }
    working_hours { 7 }
  end
end
