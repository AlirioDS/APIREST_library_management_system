class BorrowingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (user.librarian? || user == record.user)
  end

  def return?
    user.present? && user.librarian?
  end

  def user_borrowings?
    user.present? && user.librarian?
  end

  def book_borrowings?
    user.present? && user.librarian?
  end

  class Scope < Scope
    def resolve
      if user.librarian?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
