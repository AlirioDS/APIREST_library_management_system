require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:borrowings).dependent(:destroy) }
    it { should have_many(:borrowed_books).through(:borrowings).source(:book) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email_address) }
    it { should validate_uniqueness_of(:email_address).case_insensitive }
    it { should validate_length_of(:password).is_at_least(8) }
    it { should have_secure_password }
  end

  describe 'enums' do
    it 'defines role enum with string values' do
      expect(User.roles).to eq({ 'member' => 'member', 'librarian' => 'librarian' })
    end
  end

  describe 'scopes' do
    let!(:member) { create(:user, :member) }
    let!(:librarian) { create(:user, :librarian) }

    it 'returns only members' do
      expect(User.member).to include(member)
      expect(User.member).not_to include(librarian)
    end

    it 'returns only librarians' do
      expect(User.librarian).to include(librarian)
      expect(User.librarian).not_to include(member)
    end
  end

  describe 'JWT token methods' do
    let(:user) { create(:user) }

    describe '#generate_jwt_token' do
      it 'generates a valid JWT token' do
        token = user.generate_jwt_token
        expect(token).to be_present
        expect(token.split('.').length).to eq(3) # JWT has 3 parts
      end

      it 'includes user information in payload' do
        token = user.generate_jwt_token
        payload = User.decode_jwt_token(token)

        expect(payload['user_id']).to eq(user.id)
        expect(payload['email']).to eq(user.email_address)
        expect(payload['role']).to eq(user.role)
      end
    end

    describe '#generate_refresh_token' do
      it 'generates a valid refresh token' do
        token = user.generate_refresh_token
        expect(token).to be_present
        expect(token.split('.').length).to eq(3)
      end
    end

    describe '.decode_jwt_token' do
      it 'decodes valid token' do
        token = user.generate_jwt_token
        payload = User.decode_jwt_token(token)
        expect(payload).to be_present
        expect(payload['user_id']).to eq(user.id)
      end

      it 'returns nil for invalid token' do
        payload = User.decode_jwt_token('invalid.token.here')
        expect(payload).to be_nil
      end

      it 'returns nil for expired token' do
        expired_token = JWT.encode(
          { user_id: user.id, exp: 1.hour.ago.to_i },
          User.jwt_secret_key,
          'HS256'
        )
        payload = User.decode_jwt_token(expired_token)
        expect(payload).to be_nil
      end
    end
  end

  describe 'role methods' do
    let(:member) { create(:user, :member) }
    let(:librarian) { create(:user, :librarian) }

    describe '#member?' do
      it 'returns true for member users' do
        expect(member.member?).to be_truthy
      end

      it 'returns false for librarian users' do
        expect(librarian.member?).to be_falsey
      end
    end

    describe '#librarian?' do
      it 'returns true for librarian users' do
        expect(librarian.librarian?).to be_truthy
      end

      it 'returns false for member users' do
        expect(member.librarian?).to be_falsey
      end
    end
  end

  describe 'borrowing helper methods' do
    let(:member) { create(:user, :member) }
    let(:librarian) { create(:user, :librarian) }
    let(:book) { create(:book, :available) }

    describe '#active_borrowings' do
      it 'returns only active borrowings' do
        active_borrowing = create(:borrowing, user: member, book: book)
        returned_borrowing = create(:borrowing, :returned, user: member)

        expect(member.active_borrowings).to include(active_borrowing)
        expect(member.active_borrowings).not_to include(returned_borrowing)
      end
    end

    describe '#can_borrow_book?' do
      context 'when user is a member' do
        it 'returns true for available book not already borrowed' do
          expect(member.can_borrow_book?(book)).to be_truthy
        end

        it 'returns false for book already borrowed by user' do
          create(:borrowing, user: member, book: book)
          expect(member.can_borrow_book?(book)).to be_falsey
        end

        it 'returns false for unavailable book' do
          unavailable_book = create(:book, :checked_out)
          expect(member.can_borrow_book?(unavailable_book)).to be_falsey
        end
      end

      context 'when user is a librarian' do
        it 'returns false' do
          expect(librarian.can_borrow_book?(book)).to be_falsey
        end
      end
    end

    describe '#has_borrowed_book?' do
      it 'returns true when user has active borrowing for book' do
        create(:borrowing, user: member, book: book)
        expect(member.has_borrowed_book?(book)).to be_truthy
      end

      it 'returns false when user has no borrowing for book' do
        expect(member.has_borrowed_book?(book)).to be_falsey
      end

      it 'returns false when user has returned the book' do
        create(:borrowing, :returned, user: member, book: book)
        expect(member.has_borrowed_book?(book)).to be_falsey
      end
    end

    describe '#overdue_borrowings' do
      it 'returns only overdue borrowings' do
        overdue_borrowing = create(:borrowing, :overdue, user: member)
        current_borrowing = create(:borrowing, user: member)

        expect(member.overdue_borrowings).to include(overdue_borrowing)
        expect(member.overdue_borrowings).not_to include(current_borrowing)
      end
    end

    describe '#borrowings_count' do
      it 'returns count of active borrowings' do
        create_list(:borrowing, 3, user: member)
        create(:borrowing, :returned, user: member)

        expect(member.borrowings_count).to eq(3)
      end
    end
  end

  describe 'normalization' do
    it 'normalizes email address to lowercase' do
      user = create(:user, email_address: 'TEST@EXAMPLE.COM')
      expect(user.email_address).to eq('test@example.com')
    end
  end
end
