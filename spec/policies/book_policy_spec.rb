require 'rails_helper'

RSpec.describe BookPolicy, type: :policy do
  let(:member) { create(:user, :member) }
  let(:librarian) { create(:user, :librarian) }
  let(:book) { create(:book) }

  describe '#index?' do
    it 'allows authenticated users to view books' do
      expect(BookPolicy.new(member, book).index?).to be_truthy
      expect(BookPolicy.new(librarian, book).index?).to be_truthy
    end

    it 'denies unauthenticated users' do
      expect(BookPolicy.new(nil, book).index?).to be_falsey
    end
  end

  describe '#show?' do
    it 'allows authenticated users to view book details' do
      expect(BookPolicy.new(member, book).show?).to be_truthy
      expect(BookPolicy.new(librarian, book).show?).to be_truthy
    end

    it 'denies unauthenticated users' do
      expect(BookPolicy.new(nil, book).show?).to be_falsey
    end
  end

  describe '#create?' do
    it 'allows librarians to create books' do
      expect(BookPolicy.new(librarian, book).create?).to be_truthy
    end

    it 'denies members from creating books' do
      expect(BookPolicy.new(member, book).create?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(BookPolicy.new(nil, book).create?).to be_falsey
    end
  end

  describe '#update?' do
    it 'allows librarians to update books' do
      expect(BookPolicy.new(librarian, book).update?).to be_truthy
    end

    it 'denies members from updating books' do
      expect(BookPolicy.new(member, book).update?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(BookPolicy.new(nil, book).update?).to be_falsey
    end
  end

  describe '#destroy?' do
    it 'allows librarians to delete books' do
      expect(BookPolicy.new(librarian, book).destroy?).to be_truthy
    end

    it 'denies members from deleting books' do
      expect(BookPolicy.new(member, book).destroy?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(BookPolicy.new(nil, book).destroy?).to be_falsey
    end
  end

  describe '#search?' do
    it 'allows authenticated users to search books' do
      expect(BookPolicy.new(member, book).search?).to be_truthy
      expect(BookPolicy.new(librarian, book).search?).to be_truthy
    end

    it 'denies unauthenticated users' do
      expect(BookPolicy.new(nil, book).search?).to be_falsey
    end
  end

  describe '#borrow?' do
    it 'allows members to borrow books' do
      expect(BookPolicy.new(member, book).borrow?).to be_truthy
    end

    it 'denies librarians from borrowing books' do
      expect(BookPolicy.new(librarian, book).borrow?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(BookPolicy.new(nil, book).borrow?).to be_falsey
    end
  end

  describe '#show_borrowings?' do
    it 'allows librarians to view borrowing history' do
      expect(BookPolicy.new(librarian, book).show_borrowings?).to be_truthy
    end

    it 'denies members from viewing borrowing history' do
      expect(BookPolicy.new(member, book).show_borrowings?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(BookPolicy.new(nil, book).show_borrowings?).to be_falsey
    end
  end
end

RSpec.describe BorrowingPolicy, type: :policy do
  let(:member) { create(:user, :member) }
  let(:other_member) { create(:user, :member) }
  let(:librarian) { create(:user, :librarian) }
  let(:borrowing) { create(:borrowing, user: member) }

  describe '#index?' do
    it 'allows authenticated users to view borrowings' do
      expect(BorrowingPolicy.new(member, borrowing).index?).to be_truthy
      expect(BorrowingPolicy.new(librarian, borrowing).index?).to be_truthy
    end

    it 'denies unauthenticated users' do
      expect(BorrowingPolicy.new(nil, borrowing).index?).to be_falsey
    end
  end

  describe '#show?' do
    it 'allows borrowing owner to view details' do
      expect(BorrowingPolicy.new(member, borrowing).show?).to be_truthy
    end

    it 'allows librarians to view any borrowing' do
      expect(BorrowingPolicy.new(librarian, borrowing).show?).to be_truthy
    end

    it 'denies other members from viewing borrowing' do
      expect(BorrowingPolicy.new(other_member, borrowing).show?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(BorrowingPolicy.new(nil, borrowing).show?).to be_falsey
    end
  end

  describe '#return?' do
    it 'allows librarians to process returns' do
      expect(BorrowingPolicy.new(librarian, borrowing).return?).to be_truthy
    end

    it 'denies members from processing returns' do
      expect(BorrowingPolicy.new(member, borrowing).return?).to be_falsey
      expect(BorrowingPolicy.new(other_member, borrowing).return?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(BorrowingPolicy.new(nil, borrowing).return?).to be_falsey
    end
  end

  describe 'Scope' do
    let!(:member_borrowing) { create(:borrowing, user: member) }
    let!(:other_borrowing) { create(:borrowing, user: other_member) }

    it 'shows all borrowings to librarians' do
      scope = Pundit.policy_scope(librarian, Borrowing)
      expect(scope).to include(member_borrowing, other_borrowing)
    end

    it 'shows only own borrowings to members' do
      scope = Pundit.policy_scope(member, Borrowing)
      expect(scope).to include(member_borrowing)
      expect(scope).not_to include(other_borrowing)
    end
  end
end

RSpec.describe UserPolicy, type: :policy do
  let(:member) { create(:user, :member) }
  let(:other_member) { create(:user, :member) }
  let(:librarian) { create(:user, :librarian) }

  describe '#index?' do
    it 'allows librarians to view all users' do
      expect(UserPolicy.new(librarian, member).index?).to be_truthy
    end

    it 'denies members from viewing user list' do
      expect(UserPolicy.new(member, other_member).index?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(UserPolicy.new(nil, member).index?).to be_falsey
    end
  end

  describe '#show?' do
    it 'allows users to view their own profile' do
      expect(UserPolicy.new(member, member).show?).to be_truthy
    end

    it 'allows librarians to view any user profile' do
      expect(UserPolicy.new(librarian, member).show?).to be_truthy
    end

    it 'denies members from viewing other profiles' do
      expect(UserPolicy.new(member, other_member).show?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(UserPolicy.new(nil, member).show?).to be_falsey
    end
  end

  describe '#create?' do
    it 'allows librarians to create users' do
      expect(UserPolicy.new(librarian, member).create?).to be_truthy
    end

    it 'denies members from creating users' do
      expect(UserPolicy.new(member, other_member).create?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(UserPolicy.new(nil, member).create?).to be_falsey
    end
  end

  describe '#update?' do
    it 'allows users to update their own profile' do
      expect(UserPolicy.new(member, member).update?).to be_truthy
    end

    it 'allows librarians to update any user profile' do
      expect(UserPolicy.new(librarian, member).update?).to be_truthy
    end

    it 'denies members from updating other profiles' do
      expect(UserPolicy.new(member, other_member).update?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(UserPolicy.new(nil, member).update?).to be_falsey
    end
  end

  describe '#destroy?' do
    it 'allows librarians to delete other users' do
      expect(UserPolicy.new(librarian, member).destroy?).to be_truthy
    end

    it 'prevents librarians from deleting themselves' do
      expect(UserPolicy.new(librarian, librarian).destroy?).to be_falsey
    end

    it 'denies members from deleting users' do
      expect(UserPolicy.new(member, other_member).destroy?).to be_falsey
      expect(UserPolicy.new(member, member).destroy?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(UserPolicy.new(nil, member).destroy?).to be_falsey
    end
  end

  describe '#change_role?' do
    it 'allows librarians to change other user roles' do
      expect(UserPolicy.new(librarian, member).change_role?).to be_truthy
    end

    it 'prevents librarians from changing their own role' do
      expect(UserPolicy.new(librarian, librarian).change_role?).to be_falsey
    end

    it 'denies members from changing roles' do
      expect(UserPolicy.new(member, other_member).change_role?).to be_falsey
      expect(UserPolicy.new(member, member).change_role?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(UserPolicy.new(nil, member).change_role?).to be_falsey
    end
  end

  describe '#show_borrowings?' do
    it 'allows librarians to view user borrowing history' do
      expect(UserPolicy.new(librarian, member).show_borrowings?).to be_truthy
    end

    it 'denies members from viewing borrowing history' do
      expect(UserPolicy.new(member, other_member).show_borrowings?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(UserPolicy.new(nil, member).show_borrowings?).to be_falsey
    end
  end

  describe 'Scope' do
    let!(:librarian) { create(:user, :librarian) }
    let!(:member1) { create(:user, :member) }
    let!(:member2) { create(:user, :member) }

    it 'shows all users to librarians' do
      scope = Pundit.policy_scope(librarian, User)
      expect(scope).to include(librarian, member1, member2)
    end

    it 'shows only self to members' do
      scope = Pundit.policy_scope(member1, User)
      expect(scope).to include(member1)
      expect(scope).not_to include(member2, librarian)
    end
  end
end

RSpec.describe DashboardPolicy, type: :policy do
  let(:member) { create(:user, :member) }
  let(:librarian) { create(:user, :librarian) }

  describe '#librarian?' do
    it 'allows librarians to access librarian dashboard' do
      expect(DashboardPolicy.new(librarian, :dashboard).librarian?).to be_truthy
    end

    it 'denies members from accessing librarian dashboard' do
      expect(DashboardPolicy.new(member, :dashboard).librarian?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(DashboardPolicy.new(nil, :dashboard).librarian?).to be_falsey
    end
  end

  describe '#member?' do
    it 'allows members to access member dashboard' do
      expect(DashboardPolicy.new(member, :dashboard).member?).to be_truthy
    end

    it 'denies librarians from accessing member dashboard' do
      expect(DashboardPolicy.new(librarian, :dashboard).member?).to be_falsey
    end

    it 'denies unauthenticated users' do
      expect(DashboardPolicy.new(nil, :dashboard).member?).to be_falsey
    end
  end
end
