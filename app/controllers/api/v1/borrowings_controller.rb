class Api::V1::BorrowingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_borrowing, only: [:show, :return_book]
  before_action :set_book, only: [:borrow_book]

  # GET /api/v1/borrowings
  def index
    @borrowings = policy_scope(Borrowing)
    authorize Borrowing
    
    # Apply filters
    @borrowings = @borrowings.where(status: params[:status]) if params[:status].present?
    @borrowings = @borrowings.where(user_id: params[:user_id]) if params[:user_id].present? && current_user.librarian?
    
    # Pagination
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min
    offset = (page - 1) * per_page
    
    @borrowings = @borrowings.includes(:user, :book)
                            .order(borrowed_at: :desc)
                            .limit(per_page)
                            .offset(offset)
    
    total_count = policy_scope(Borrowing).count
    
    render json: {
      borrowings: @borrowings.map { |borrowing| borrowing_data(borrowing) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }, status: :ok
  end

  # GET /api/v1/borrowings/:id
  def show
    authorize @borrowing
    
    render json: {
      borrowing: borrowing_data(@borrowing, detailed: true)
    }, status: :ok
  end

  # POST /api/v1/books/:book_id/borrow
  def borrow_book
    authorize @book, :borrow?
    
    unless current_user.can_borrow_book?(@book)
      if current_user.has_borrowed_book?(@book)
        render json: { error: 'You already have this book borrowed' }, status: :unprocessable_entity
      elsif !@book.available?
        render json: { error: 'Book is not available for borrowing' }, status: :unprocessable_entity
      else
        render json: { error: 'You cannot borrow this book' }, status: :unprocessable_entity
      end
      return
    end
    
    @borrowing = current_user.borrowings.build(book: @book)
    
    if @borrowing.save
      render json: {
        message: 'Book borrowed successfully',
        borrowing: borrowing_data(@borrowing, detailed: true)
      }, status: :created
    else
      render json: {
        error: 'Failed to borrow book',
        details: @borrowing.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/borrowings/:id/return
  def return_book
    authorize @borrowing, :return?
    
    if @borrowing.returned_at.present?
      render json: { error: 'Book has already been returned' }, status: :unprocessable_entity
      return
    end
    
    if @borrowing.return_book!
      render json: {
        message: 'Book returned successfully',
        borrowing: borrowing_data(@borrowing, detailed: true)
      }, status: :ok
    else
      render json: {
        error: 'Failed to return book',
        details: @borrowing.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/users/:user_id/borrowings (for librarians to see user's borrowings)
  def user_borrowings
    @user = User.find(params[:user_id])
    authorize @user, :show_borrowings?
    
    @borrowings = @user.borrowings.includes(:book).order(borrowed_at: :desc)
    
    render json: {
      user: {
        id: @user.id,
        first_name: @user.first_name,
        last_name: @user.last_name,
        email_address: @user.email_address
      },
      borrowings: @borrowings.map { |borrowing| borrowing_data(borrowing) }
    }, status: :ok
  end

  # GET /api/v1/books/:book_id/borrowings (for librarians to see book's borrowing history)
  def book_borrowings
    @book = Book.find(params[:book_id])
    authorize @book, :show_borrowings?
    
    @borrowings = @book.borrowings.includes(:user).order(borrowed_at: :desc)
    
    render json: {
      book: {
        id: @book.id,
        title: @book.title,
        author: @book.author
      },
      borrowings: @borrowings.map { |borrowing| borrowing_data(borrowing) }
    }, status: :ok
  end

  private

  def set_borrowing
    @borrowing = Borrowing.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Borrowing record not found' }, status: :not_found
  end

  def set_book
    @book = Book.find(params[:book_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Book not found' }, status: :not_found
  end

  def borrowing_data(borrowing, detailed: false)
    data = {
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
      returned_at: borrowing.returned_at,
      status: borrowing.status,
      overdue: borrowing.overdue?,
      days_until_due: borrowing.days_until_due
    }
    
    if detailed
      data.merge!({
        days_overdue: borrowing.days_overdue,
        borrowing_period_days: borrowing.borrowing_period_days,
        created_at: borrowing.created_at,
        updated_at: borrowing.updated_at
      })
    end
    
    data
  end
end 
