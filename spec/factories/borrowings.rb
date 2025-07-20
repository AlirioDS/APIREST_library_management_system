FactoryBot.define do
  factory :borrowing do
    association :user, factory: [:user, :member]
    association :book, factory: [:book, :available]
    borrowed_at { Time.current }
    due_at { 2.weeks.from_now }
    status { 'borrowed' }
    returned_at { nil }

    trait :borrowed do
      status { 'borrowed' }
      returned_at { nil }
    end

    trait :returned do
      status { 'returned' }
      returned_at { Time.current }
    end

    trait :overdue do
      status { 'overdue' }
      borrowed_at { 3.weeks.ago }
      due_at { 1.week.ago }
      returned_at { nil }
    end

    trait :due_today do
      borrowed_at { 2.weeks.ago }
      due_at { Date.current.end_of_day }
      status { 'borrowed' }
    end

    trait :due_soon do
      borrowed_at { 1.week.ago }
      due_at { 2.days.from_now }
      status { 'borrowed' }
    end

    trait :recent do
      borrowed_at { 1.day.ago }
      due_at { 13.days.from_now }
    end
  end
end 
