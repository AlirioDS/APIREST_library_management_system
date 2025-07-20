FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    author { Faker::Book.author }
    sequence(:isbn) { |n| "978-#{n.to_s.rjust(10, '0')}" }
    description { Faker::Lorem.paragraph }
    genre { %w[Fiction Non-Fiction Science Fantasy Mystery Romance Biography].sample }
    publication_year { rand(1950..Date.current.year) }
    publisher { Faker::Book.publisher }
    total_copies { 10 }
    available_copies { total_copies }
    status { 'available' }

    trait :available do
      status { 'available' }
      available_copies { total_copies }
    end

    trait :checked_out do
      status { 'checked_out' }
      available_copies { 0 }
    end

    trait :maintenance do
      status { 'maintenance' }
      available_copies { 0 }
    end

    trait :lost do
      status { 'lost' }
      available_copies { 0 }
    end

    trait :popular do
      after(:create) do |book|
        create_list(:borrowing, 5, book: book)
      end
    end

    trait :fiction do
      genre { 'Fiction' }
    end

    trait :programming do
      genre { 'Programming' }
      title { 'Clean Code' }
      author { 'Robert C. Martin' }
    end
  end
end
