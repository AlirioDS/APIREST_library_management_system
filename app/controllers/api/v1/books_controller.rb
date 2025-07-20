class Api::V1::BooksController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy, :manage_status]
  before_action :set_current_user_optional, only: [:index, :show, :search]
  before_action :set_book, only: [:show, :update, :destroy, :manage_status]

  # GET /api/v1/books
  def index
    @books = Book.all
    # No authorization needed for public browsing
    
    # Apply search and filters
    @books = @books.search(params[:search]) if params[:search].present?
    @books = @books.by_genre(params[:genre]) if params[:genre].present?
    @books = @books.by_author(params[:author]) if params[:author].present?
    @books = @books.by_title(params[:title]) if params[:title].present?
    
    # Apply status filter
    @books = @books.where(status: params[:status]) if params[:status].present?
    
    # Pagination (basic)
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min
    offset = (page - 1) * per_page
    
    @books = @books.order(:title).limit(per_page).offset(offset)
    total_count = policy_scope(Book).count
    
    render json: {
      books: @books.map { |book| book_data(book) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }, status: :ok
  end

  # GET /api/v1/books/:id
  def show
    # No authorization needed for public viewing
    
    render json: {
      book: book_data(@book, detailed: true)
    }, status: :ok
  end

  # POST /api/v1/books
  def create
    @book = Book.new(book_params)
    authorize @book
    
    if @book.save
      render json: {
        message: 'Book created successfully',
        book: book_data(@book, detailed: true)
      }, status: :created
    else
      render json: {
        error: 'Book creation failed',
        details: @book.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/books/:id
  def update
    authorize @book
    
    if @book.update(book_params)
      render json: {
        message: 'Book updated successfully',
        book: book_data(@book, detailed: true)
      }, status: :ok
    else
      render json: {
        error: 'Book update failed',
        details: @book.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/books/:id
  def destroy
    authorize @book
    
    if @book.destroy
      render json: {
        message: 'Book deleted successfully'
      }, status: :ok
    else
      render json: {
        error: 'Book deletion failed'
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/books/search
  def search
    # No authorization needed for public search
    
    query = params[:q] || params[:search]
    
    if query.blank?
      render json: { error: 'Search query is required' }, status: :bad_request
      return
    end
    
    @books = Book.search(query).limit(50)
    
    render json: {
      books: @books.map { |book| book_data(book) },
      search_query: query,
      results_count: @books.count
    }, status: :ok
  end

  # PATCH /api/v1/books/:id/status
  def manage_status
    authorize @book, :manage_status?
    
    new_status = params[:status]
    
    unless Book.statuses.key?(new_status)
      render json: {
        error: 'Invalid status',
        valid_statuses: Book.statuses.keys
      }, status: :bad_request
      return
    end
    
    if @book.update(status: new_status)
      render json: {
        message: 'Book status updated successfully',
        book: book_data(@book, detailed: true)
      }, status: :ok
    else
      render json: {
        error: 'Status update failed',
        details: @book.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_book
    @book = Book.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Book not found' }, status: :not_found
  end

  def book_params
    params.permit(
      :title, :author, :isbn, :description, :genre, 
      :publication_year, :publisher, :total_copies, 
      :available_copies, :status
    )
  end

  def book_data(book, detailed: false)
    data = {
      id: book.id,
      title: book.title,
      author: book.author,
      genre: book.genre,
      status: book.status,
      available_copies: book.available_copies,
      total_copies: book.total_copies,
      available: book.available?
    }
    
    if detailed
      data.merge!({
        isbn: book.isbn,
        description: book.description,
        publication_year: book.publication_year,
        publisher: book.publisher,
        published_info: book.published_info,
        full_title: book.full_title,
        created_at: book.created_at,
        updated_at: book.updated_at
      })
    end
    
    data
  end
end 
