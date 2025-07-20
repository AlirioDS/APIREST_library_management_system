class BookPolicy < ApplicationPolicy
  def index?
    user.present? # Both members and librarians can view books
  end

  def show?
    user.present? # Both members and librarians can view book details
  end

  def create?
    user&.librarian? # Only librarians can add books
  end

  def update?
    user&.librarian? # Only librarians can edit books
  end

  def destroy?
    user&.librarian? # Only librarians can delete books
  end

  def search?
    user.present? # Both members and librarians can search books
  end

  def borrow?
    user&.member? # Only members can borrow books
  end

  def show_borrowings?
    user&.librarian? # Only librarians can view borrowing history
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present?
        # All authenticated users can see all books
        scope.all
      else
        # Unauthenticated users can't see any books
        scope.none
      end
    end
  end

  # Additional permissions for library-specific actions
  def manage_status?
    user&.librarian? # Only librarians can change book status
  end

  def manage_copies?
    user&.librarian? # Only librarians can manage copy counts
  end

  def check_out?
    user.present? # This would be for future checkout functionality
  end

  def return_book?
    user.present? # This would be for future return functionality
  end
end
