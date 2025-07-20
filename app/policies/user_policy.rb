class UserPolicy < ApplicationPolicy
  def index?
    user&.librarian? # Only librarians can view all users
  end

  def show?
    user.present? && (user.librarian? || user == record) # Librarians or self
  end

  def create?
    user&.librarian? # Only librarians can create users
  end

  def update?
    user.present? && (user.librarian? || user == record) # Librarians or self
  end

  def destroy?
    user&.librarian? && user != record # Librarians can't delete themselves
  end

  def change_role?
    user&.librarian? && user != record # Only librarians can change roles
  end

  def show_borrowings?
    user&.librarian? # Only librarians can view user borrowing history
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.librarian?
        scope.all # Librarians can see all users
      else
        scope.where(id: user.id) # Members can only see themselves
      end
    end
  end

  # Custom permissions for user-specific actions
  def update_profile?
    user.present? && (user.librarian? || user == record)
  end

  def change_password?
    user.present? && user == record
  end
end
