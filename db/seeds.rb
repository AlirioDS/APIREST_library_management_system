# Create default users for Library Management System

puts "🏛️ Creating Library Management System seed data..."

# Librarian users
librarian1 = User.find_or_create_by(email_address: 'librarian@library.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.first_name = 'Sarah'
  user.last_name = 'Johnson'
  user.role = 'librarian'
end

librarian2 = User.find_or_create_by(email_address: 'head.librarian@library.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.first_name = 'Michael'
  user.last_name = 'Chen'
  user.role = 'librarian'
end

# Member users
member1 = User.find_or_create_by(email_address: 'member1@example.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.first_name = 'Emma'
  user.last_name = 'Davis'
  user.role = 'member'
end

member2 = User.find_or_create_by(email_address: 'member2@example.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.first_name = 'James'
  user.last_name = 'Wilson'
  user.role = 'member'
end

member3 = User.find_or_create_by(email_address: 'student@university.edu') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.first_name = 'Alice'
  user.last_name = 'Brown'
  user.role = 'member'
end

puts "✅ Created users:"
puts "👑 Librarians: librarian@library.com, head.librarian@library.com"
puts "👤 Members: member1@example.com, member2@example.com, student@university.edu"

# Clean up previous borrowings to avoid duplicates on re-seed
Borrowing.destroy_all

# Sample Books
books_data = [
  {
    title: "To Kill a Mockingbird",
    author: "Harper Lee",
    isbn: "9780061120084",
    description: "A classic novel about racial injustice and childhood in the American South.",
    genre: "Fiction",
    publication_year: 1960,
    publisher: "Harper Perennial",
    total_copies: 5,
    available_copies: 3,
    status: "available"
  },
  {
    title: "1984",
    author: "George Orwell",
    isbn: "9780451524935",
    description: "A dystopian social science fiction novel about totalitarian control.",
    genre: "Science Fiction",
    publication_year: 1949,
    publisher: "Signet Classics",
    total_copies: 4,
    available_copies: 2,
    status: "available"
  },
  {
    title: "Pride and Prejudice",
    author: "Jane Austen",
    isbn: "9780141439518",
    description: "A romantic novel about manners, marriage, and money in Georgian England.",
    genre: "Romance",
    publication_year: 1813,
    publisher: "Penguin Classics",
    total_copies: 3,
    available_copies: 3,
    status: "available"
  },
  {
    title: "The Great Gatsby",
    author: "F. Scott Fitzgerald",
    isbn: "9780743273565",
    description: "A classic American novel set in the Jazz Age.",
    genre: "Fiction",
    publication_year: 1925,
    publisher: "Scribner",
    total_copies: 6,
    available_copies: 4,
    status: "available"
  },
  {
    title: "The Catcher in the Rye",
    author: "J.D. Salinger",
    isbn: "9780316769174",
    description: "A coming-of-age story about teenage rebellion and alienation.",
    genre: "Fiction",
    publication_year: 1951,
    publisher: "Little, Brown and Company",
    total_copies: 2,
    available_copies: 0,
    status: "checked_out"
  },
  {
    title: "Dune",
    author: "Frank Herbert",
    isbn: "9780441172719",
    description: "A science fiction epic about politics, religion, and ecology on a desert planet.",
    genre: "Science Fiction",
    publication_year: 1965,
    publisher: "Ace Books",
    total_copies: 3,
    available_copies: 2,
    status: "available"
  },
  {
    title: "The Lord of the Rings",
    author: "J.R.R. Tolkien",
    isbn: "9780544003415",
    description: "An epic fantasy trilogy about the quest to destroy the One Ring.",
    genre: "Fantasy",
    publication_year: 1954,
    publisher: "Houghton Mifflin",
    total_copies: 4,
    available_copies: 3,
    status: "available"
  },
  {
    title: "Introduction to Algorithms",
    author: "Thomas H. Cormen",
    isbn: "9780262033848",
    description: "A comprehensive textbook on computer algorithms.",
    genre: "Computer Science",
    publication_year: 2009,
    publisher: "MIT Press",
    total_copies: 2,
    available_copies: 1,
    status: "available"
  },
  {
    title: "Clean Code",
    author: "Robert C. Martin",
    isbn: "9780132350884",
    description: "A handbook of agile software craftsmanship.",
    genre: "Programming",
    publication_year: 2008,
    publisher: "Prentice Hall",
    total_copies: 3,
    available_copies: 2,
    status: "available"
  },
  {
    title: "The Design of Everyday Things",
    author: "Don Norman",
    isbn: "9780465050659",
    description: "A book about user-centered design and usability.",
    genre: "Design",
    publication_year: 2013,
    publisher: "Basic Books",
    total_copies: 2,
    available_copies: 0,
    status: "maintenance"
  }
]

books_data.each do |book_attrs|
  Book.find_or_create_by(isbn: book_attrs[:isbn]) do |book|
    book.assign_attributes(book_attrs)
  end
end

# Reset available copies before creating new borrowings
Book.all.each do |book|
  book.update_column(:available_copies, book.total_copies)
end

puts "📚 Created #{Book.count} sample books"

# Sample Borrowings
puts "🔄 Creating sample borrowings..."

begin
  # Member 1: Emma Davis (member1@example.com)
  emma = User.find_by!(email_address: 'member1@example.com')
  book1 = Book.find_by!(title: 'To Kill a Mockingbird')
  book2 = Book.find_by!(title: '1984')
  book3 = Book.find_by!(title: 'The Great Gatsby')

  # 1. Overdue book
  Borrowing.create!(
    user: emma,
    book: book1,
    borrowed_at: 3.weeks.ago,
    due_at: 1.week.ago,
    status: 'overdue'
  )

  # 2. Active (current) borrowing
  Borrowing.create!(
    user: emma,
    book: book2,
    borrowed_at: 1.week.ago,
    due_at: 1.week.from_now
  )

  # 3. Returned book for history
  Borrowing.create!(
    user: emma,
    book: Book.find_by!(title: 'The Lord of the Rings'),
    borrowed_at: 2.months.ago,
    due_at: 6.weeks.ago,
    returned_at: 5.weeks.ago,
    status: 'returned'
  )

  # Member 2: James Wilson (member2@example.com)
  james = User.find_by!(email_address: 'member2@example.com')
  book4 = Book.find_by!(title: 'Pride and Prejudice')
  book5 = Book.find_by!(title: 'Dune')

  # 4. Returned book
  Borrowing.create!(
    user: james,
    book: book4,
    borrowed_at: 1.month.ago,
    due_at: 2.weeks.ago,
    returned_at: 1.week.ago,
    status: 'returned'
  )
  
  # 5. Another active borrowing for a different user
  Borrowing.create!(
    user: james,
    book: book5,
    borrowed_at: 5.days.ago,
    due_at: 9.days.from_now
  )

  # 6. More history for James
  Borrowing.create!(
    user: james,
    book: Book.find_by!(title: 'The Great Gatsby'),
    borrowed_at: 3.months.ago,
    due_at: 10.weeks.ago,
    returned_at: 9.weeks.ago,
    status: 'returned'
  )

  # Member 3: Alice Brown (student@university.edu) - New history
  alice = User.find_by!(email_address: 'student@university.edu')
  
  # 7. Returned book for Alice
  Borrowing.create!(
    user: alice,
    book: Book.find_by!(title: 'Clean Code'),
    borrowed_at: 6.weeks.ago,
    due_at: 4.weeks.ago,
    returned_at: 3.weeks.ago,
    status: 'returned'
  )

  # 8. Active borrowing for Alice
  Borrowing.create!(
    user: alice,
    book: Book.find_by!(title: 'Introduction to Algorithms'),
    borrowed_at: 2.days.ago,
    due_at: 12.days.from_now
  )

  puts "✅ Created #{Borrowing.count} sample borrowings."
  puts "    - #{Borrowing.overdue.count} overdue book(s)."
  puts "    - #{Borrowing.active.where.not(status: 'overdue').count} active borrowing(s)."
  puts "    - #{Borrowing.returned.count} returned book(s)."

rescue ActiveRecord::RecordNotFound => e
  puts "⚠️  Could not create borrowings. Make sure users and books exist. Error: #{e.message}"
end


puts "📖 Available books: #{Book.available.count}"
puts "📋 Book genres: #{Book.distinct.pluck(:genre).compact.sort.join(', ')}"

puts "\n🎉 Library Management System seed data created successfully!"
puts "\n🔑 Login credentials:"
puts "👑 Librarian: librarian@library.com (password: password123)"
puts "👑 Head Librarian: head.librarian@library.com (password: password123)"
puts "👤 Member: member1@example.com (password: password123)"
puts "👤 Student: student@university.edu (password: password123)"
puts "\n📋 System Features:"
puts "✅ Only librarians can add/edit/delete books"
puts "✅ Both librarians and members can view and search books"
puts "✅ Role-based access control with Pundit"
puts "✅ JWT authentication with refresh tokens"
