class Api::V1::DashboardController < ApplicationController
  before_action :authenticate_user!

  # GET /api/v1/dashboard/librarian
  def librarian
    authorize :dashboard, :librarian?

    render json: {
      dashboard: {
        overview: librarian_overview,
        books_due_today: books_due_today,
        overdue_members: overdue_members_list,
        recent_borrowings: recent_borrowings,
        popular_books: popular_books
      }
    }, status: :ok
  end

  # GET /api/v1/dashboard/member
  def member
    authorize :dashboard, :member?

    render json: {
      dashboard: {
        overview: member_overview,
        active_borrowings: current_user_borrowings,
        borrowing_history: user_borrowing_history,
        recommendations: book_recommendations
      }
    }, status: :ok
  end

  private

  # Librarian dashboard data
  def librarian_overview
    {
      total_books: Book.count,
      total_copies: Book.sum(:total_copies),
      available_books: Book.where(status: "available").count,
      borrowed_books: Borrowing.active.count,
      total_members: User.member.count,
      overdue_books: Borrowing.overdue.count,
      books_due_today: Borrowing.active.joins(:book)
                               .where("due_at::date = ?", Date.current).count,
      books_due_this_week: Borrowing.active.joins(:book)
                                   .where("due_at BETWEEN ? AND ?",
                                          Date.current,
                                          Date.current + 7.days).count
    }
  end

  def books_due_today
    Borrowing.active
             .includes(:user, :book)
             .where("due_at::date = ?", Date.current)
             .order(:due_at)
             .map { |borrowing| borrowing_summary(borrowing) }
  end

  def overdue_members_list
    overdue_borrowings = Borrowing.overdue
                                 .includes(:user, :book)
                                 .group_by(&:user)

    overdue_borrowings.map do |user, borrowings|
      {
        user: {
          id: user.id,
          name: "#{user.first_name} #{user.last_name}",
          email: user.email_address
        },
        overdue_count: borrowings.count,
        total_days_overdue: borrowings.sum(&:days_overdue),
        books: borrowings.map { |b| borrowing_summary(b) }
      }
    end.sort_by { |member| -member[:total_days_overdue] }
  end

  def recent_borrowings
    Borrowing.includes(:user, :book)
             .order(borrowed_at: :desc)
             .limit(10)
             .map { |borrowing| borrowing_summary(borrowing) }
  end

  def popular_books
    Book.joins(:borrowings)
        .group("books.id")
        .select("books.*, COUNT(borrowings.id) as borrow_count")
        .order("borrow_count DESC")
        .limit(5)
        .map do |book|
          {
            id: book.id,
            title: book.title,
            author: book.author,
            times_borrowed: book.borrow_count,
            available_copies: book.available_copies,
            total_copies: book.total_copies
          }
        end
  end

  # Member dashboard data
  def member_overview
    user_borrowings = current_user.borrowings
    active_borrowings = user_borrowings.active

    {
      total_books_borrowed: user_borrowings.count,
      currently_borrowed: active_borrowings.count,
      books_returned: user_borrowings.returned.count,
      overdue_books: active_borrowings.overdue.count,
      books_due_soon: active_borrowings.due_soon(3).count,
      borrowing_limit_reached: active_borrowings.count >= 5 # Assuming 5 book limit
    }
  end

  def current_user_borrowings
    current_user.borrowings
                .active
                .includes(:book)
                .order(:due_at)
                .map { |borrowing| member_borrowing_details(borrowing) }
  end

  def user_borrowing_history
    current_user.borrowings
                .returned
                .includes(:book)
                .order(returned_at: :desc)
                .limit(10)
                .map { |borrowing| member_borrowing_details(borrowing) }
  end

  def book_recommendations
    # Simple recommendation: Popular books in genres user has borrowed
    borrowed_genres = current_user.borrowed_books.distinct.pluck(:genre).compact

    if borrowed_genres.any?
      Book.where(genre: borrowed_genres)
          .where.not(id: current_user.borrowed_books.pluck(:id))
          .where(status: "available")
          .where("available_copies > 0")
          .joins(:borrowings)
          .group("books.id")
          .order("COUNT(borrowings.id) DESC")
          .limit(5)
          .map do |book|
            {
              id: book.id,
              title: book.title,
              author: book.author,
              genre: book.genre,
              available_copies: book.available_copies
            }
          end
    else
      # New user - show most popular books
      Book.joins(:borrowings)
          .where(status: "available")
          .where("available_copies > 0")
          .group("books.id")
          .order("COUNT(borrowings.id) DESC")
          .limit(5)
          .map do |book|
            {
              id: book.id,
              title: book.title,
              author: book.author,
              genre: book.genre,
              available_copies: book.available_copies
            }
          end
    end
  end

  # Helper methods
  def borrowing_summary(borrowing)
    {
      id: borrowing.id,
      user: {
        id: borrowing.user.id,
        name: "#{borrowing.user.first_name} #{borrowing.user.last_name}",
        email: borrowing.user.email_address
      },
      book: {
        id: borrowing.book.id,
        title: borrowing.book.title,
        author: borrowing.book.author
      },
      borrowed_at: borrowing.borrowed_at,
      due_at: borrowing.due_at,
      status: borrowing.status,
      days_until_due: borrowing.days_until_due,
      days_overdue: borrowing.days_overdue,
      overdue: borrowing.overdue?
    }
  end

  def member_borrowing_details(borrowing)
    {
      id: borrowing.id,
      book: {
        id: borrowing.book.id,
        title: borrowing.book.title,
        author: borrowing.book.author,
        genre: borrowing.book.genre
      },
      borrowed_at: borrowing.borrowed_at,
      due_at: borrowing.due_at,
      returned_at: borrowing.returned_at,
      status: borrowing.status,
      days_until_due: borrowing.days_until_due,
      days_overdue: borrowing.days_overdue,
      overdue: borrowing.overdue?,
      can_renew: borrowing.active? && !borrowing.overdue? # Simple renewal logic
    }
  end
end
