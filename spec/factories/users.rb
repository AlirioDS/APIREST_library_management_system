FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'member' }

    trait :member do
      role { 'member' }
    end

    trait :librarian do
      role { 'librarian' }
      sequence(:email_address) { |n| "librarian#{n}@library.com" }
      first_name { 'Sarah' }
      last_name { 'Johnson' }
    end

    trait :with_borrowings do
      after(:create) do |user|
        create_list(:borrowing, 2, user: user)
      end
    end

    trait :with_overdue_books do
      after(:create) do |user|
        create(:borrowing, :overdue, user: user)
      end
    end
  end
end
