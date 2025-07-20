# 📚 Rails Library Management API

> **A complete Library Management System built with Rails 8, JWT authentication, and PostgreSQL**

[![Rails](https://img.shields.io/badge/Rails-8.0-red.svg)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17.5-blue.svg)](https://postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://docker.com/)
[![JWT](https://img.shields.io/badge/Auth-JWT-green.svg)](https://jwt.io/)

---

## 🎯 **Features**

### **📚 Library Management**
- **Book Inventory** - Complete CRUD operations for books
- **Advanced Search** - Search by title, author, genre, or ISBN
- **Status Tracking** - Available, checked out, maintenance, lost
- **Copy Management** - Track total vs available copies

### **👥 User Management** 
- **Role-Based Access** - Librarians and Members with different permissions
- **JWT Authentication** - Secure stateless authentication with refresh tokens
- **User Profiles** - Personal information and borrowing history

### **📖 Borrowing System**
- **Book Borrowing** - Members can borrow available books
- **Return Processing** - Track due dates and process returns
- **Overdue Management** - Automatic overdue status updates
- **Borrowing History** - Complete audit trail of all transactions

### **📊 Dashboard & Analytics**
- **Librarian Dashboard** - Overview of library statistics and operations
- **Member Dashboard** - Personal borrowing status and recommendations
- **Real-time Updates** - Live data on book availability and borrowings

---

## 🚀 **Quick Start**

### **Prerequisites**
- Docker & Docker Compose
- Git

### **1. Clone & Setup**
```bash
git clone <your-repository-url>
cd rails_api_boiler_plate

# Copy environment template
cp .env.example .env
```

### **2. Start Services**
```bash
# Start all services with Docker
docker compose -f docker-compose.development.yml up --build

# Or run in background
docker compose -f docker-compose.development.yml up -d
```

### **3. Verify Installation**
```bash
# Check API is running
curl http://localhost:3000

# Should return: Rails welcome page or API status
```

**🎉 Your API is now running at `http://localhost:3000`**

---

## 📡 **API Documentation**

### **Base URL**
```
http://localhost:3000/api/v1
```

### **Authentication**
Include JWT token in all authenticated requests:
```http
Authorization: Bearer {your_jwt_token}
```

---

## 🔐 **Authentication Endpoints**

### **Register User**
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email_address": "user@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response (201 Created):**
```json
{
  "message": "Registration successful",
  "user": {
    "id": 1,
    "email_address": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "member"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### **Login**
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email_address": "user@example.com",
  "password": "password123"
}
```

### **Refresh Token**
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "your_refresh_token_here"
}
```

### **Logout**
```http
DELETE /api/v1/auth/logout
Authorization: Bearer {token}
```

### **Get Current User**
```http
GET /api/v1/auth/me
Authorization: Bearer {token}
```

---

## 📚 **Books Endpoints**

### **Get All Books**
```http
GET /api/v1/books
```

**Optional Query Parameters:**
- `search` - Search by title, author, or genre
- `genre` - Filter by genre
- `author` - Filter by author
- `status` - Filter by availability status

**Example:**
```bash
curl "http://localhost:3000/api/v1/books?search=programming&genre=Technology"
```

### **Get Single Book**
```http
GET /api/v1/books/{id}
```

### **Create Book** (Librarians only)
```http
POST /api/v1/books
Authorization: Bearer {librarian_token}
Content-Type: application/json

{
  "title": "Clean Code",
  "author": "Robert C. Martin",
  "isbn": "978-0132350884",
  "genre": "Programming",
  "description": "A handbook of agile software craftsmanship",
  "publication_year": 2008,
  "publisher": "Prentice Hall",
  "total_copies": 5,
  "available_copies": 5
}
```

### **Update Book** (Librarians only)
```http
PATCH /api/v1/books/{id}
Authorization: Bearer {librarian_token}
Content-Type: application/json
```

### **Delete Book** (Librarians only)
```http
DELETE /api/v1/books/{id}
Authorization: Bearer {librarian_token}
```

### **Search Books**
```http
GET /api/v1/books/search?q=programming
```

---

## 📖 **Borrowing Endpoints**

### **Borrow Book** (Members only)
```http
POST /api/v1/books/{book_id}/borrow
Authorization: Bearer {member_token}
```

### **Return Book**
```http
PATCH /api/v1/borrowings/{borrowing_id}/return
Authorization: Bearer {token}
```

### **Get User's Borrowings**
```http
GET /api/v1/borrowings
Authorization: Bearer {token}
```

### **Get All Borrowings** (Librarians only)
```http
GET /api/v1/borrowings
Authorization: Bearer {librarian_token}
```

**Query Parameters:**
- `status` - Filter by borrowing status (borrowed, returned, overdue)
- `user_id` - Filter by user ID (librarians only)
- `page` - Page number for pagination
- `per_page` - Items per page (max 100)

---

## 👥 **User Management Endpoints**

### **Get All Users** (Librarians only)
```http
GET /api/v1/users
Authorization: Bearer {librarian_token}
```

### **Get User Details** (Own profile or librarians only)
```http
GET /api/v1/users/{id}
Authorization: Bearer {token}
```

### **Update User Role** (Librarians only)
```http
PATCH /api/v1/users/{id}/change_role
Authorization: Bearer {librarian_token}
Content-Type: application/json

{
  "role": "librarian"
}
```

### **Get User's Borrowings** (Own borrowings or librarians only)
```http
GET /api/v1/users/{id}/borrowings
Authorization: Bearer {token}
```

---

## 📊 **Dashboard Endpoints**

### **Librarian Dashboard** (Librarians only)
```http
GET /api/v1/dashboard/librarian
Authorization: Bearer {librarian_token}
```

**Response includes:**
- Total books, users, and active borrowings
- Books due today and overdue
- Popular books and recent activity
- System statistics

### **Member Dashboard** (Members only)
```http
GET /api/v1/dashboard/member
Authorization: Bearer {member_token}
```

**Response includes:**
- User's active borrowings
- Due dates and overdue items
- Borrowing history
- Recommended books

---

## 🔧 **Configuration**

### **Environment Variables**

Create `.env` file with:

```bash
# Database Configuration
DATABASE_HOST=db-postgres
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres_dev_2024
DATABASE_NAME=bd_template_dev

# Test Database
TEST_DATABASE_PASSWORD=postgres_dev_2024
TEST_DATABASE_NAME=rails_api_test

# PostgreSQL Container
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres_dev_2024
POSTGRES_DB=bd_template_dev

# Rails Configuration
RAILS_ENV=development
RAILS_MAX_THREADS=5

# Background Jobs
JOB_CONCURRENCY=2

# Security (generate with: rails secret)
SECRET_KEY_BASE=your_secret_key_here
JWT_SECRET=your_jwt_secret_here
```

### **User Roles**

| Role | Permissions |
|------|-------------|
| **Member** | Browse books, borrow/return books, view personal dashboard |
| **Librarian** | All member permissions + manage books, manage users, view all borrowings, access admin dashboard |

### **Default Users** (created by `db:seed`)

```ruby
# Librarian Account
email: "librarian@library.com"
password: "password123"

# Member Account  
email: "member@library.com"
password: "password123"
```

---

## 🧪 **Testing**

### **Run All Tests**
```bash
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rspec
```

### **Run Specific Tests**
```bash
# Model tests
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rspec spec/models/

# Controller tests
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rspec spec/controllers/

# Specific test file
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rspec spec/models/user_spec.rb
```

### **Test Coverage**
Tests are included for:
- ✅ **Models** - User, Book, Borrowing validations and associations
- ✅ **Controllers** - All API endpoints with authentication/authorization
- ✅ **Policies** - Pundit authorization rules
- ✅ **Requests** - Integration tests for full API workflows
- ✅ **Factories** - FactoryBot for test data generation

---

## 🔧 **Development**

### **Rails Console**
```bash
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rails console
```

### **Database Operations**
```bash
# Run migrations
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rails db:migrate

# Seed database
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rails db:seed

# Reset database (⚠️ destroys data)
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rails db:reset
```

### **View Logs**
```bash
# All services
docker compose -f docker-compose.development.yml logs -f

# Specific service
docker compose -f docker-compose.development.yml logs -f rails-api
```

### **Background Jobs**
```bash
# Check job queue
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rails runner "puts SolidQueue::Job.count"

# Scale workers
docker compose up --scale queue=3 -d
```

---

## 🏗️ **Architecture**

### **Services**
- **rails-api** (Port 3000) - Main Rails application
- **db-postgres** (Port 5432) - PostgreSQL database
- **queue** - Solid Queue background job processor

### **Tech Stack**
- **Backend**: Rails 8.0 API-only mode
- **Database**: PostgreSQL 17.5 with optimizations
- **Authentication**: JWT with refresh tokens
- **Authorization**: Pundit for role-based access control
- **Background Jobs**: Solid Queue
- **Testing**: RSpec, FactoryBot, Shoulda Matchers
- **Containerization**: Docker & Docker Compose

### **Key Libraries**
- `bcrypt` - Password hashing
- `jwt` - JSON Web Token handling
- `pundit` - Authorization policies
- `solid_queue` - Background job processing
- `rspec-rails` - Testing framework
- `factory_bot_rails` - Test data factories

---

## 🐛 **Troubleshooting**

### **Database Connection Issues**
```bash
# Error: "password authentication failed"
# Solution: Verify .env passwords match
docker compose -f docker-compose.development.yml down -v
docker compose -f docker-compose.development.yml up --build
```

### **Port Already In Use**
```bash
# Change port in docker-compose.development.yml
ports:
  - "3001:3000"  # Use 3001 instead of 3000
```

### **Authentication Errors**
```bash
# Clear and regenerate JWT secrets
# Update JWT_SECRET in .env
echo "JWT_SECRET=$(openssl rand -hex 64)" >> .env
```

### **Background Jobs Not Processing**
```bash
# Check Solid Queue status
docker exec -it rails_api_boiler_plate-rails-api-1 bundle exec rails runner "puts SolidQueue::Process.count"

# Restart queue service
docker compose restart queue
```

### **Clean Installation**
```bash
# Remove all containers and volumes
docker compose -f docker-compose.development.yml down -v
docker system prune -f
docker compose -f docker-compose.development.yml up --build
```

---

## 📝 **API Response Formats**

### **Success Response**
```json
{
  "message": "Operation successful",
  "data": { /* resource data */ },
  "status": "success"
}
```

### **Error Response**
```json
{
  "error": "Error message",
  "details": ["Specific error details"],
  "status": "error"
}
```

### **Validation Error Response**
```json
{
  "error": "Validation failed",
  "details": {
    "email": ["can't be blank"],
    "password": ["is too short (minimum is 8 characters)"]
  },
  "status": "error"
}
```

---

## 🚀 **Deployment**

### **Environment Setup**
```bash
# Production environment variables
RAILS_ENV=production
DATABASE_URL=postgresql://user:password@host:5432/dbname
SECRET_KEY_BASE=$(rails secret)
JWT_SECRET=$(openssl rand -hex 64)
```

### **Docker Production Build**
```bash
# Build production image
docker build -t library-api:latest .

# Run with production environment
docker run -p 3000:3000 -e RAILS_ENV=production library-api:latest
```

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
