require 'openssl'

class User < ApplicationRecord
  ITERATIONS = 20_000
  DIGEST = OpenSSL::Digest.new('SHA256')

  attr_accessor :password

  has_many :questions

  before_validation :downcase_params
  after_validation :normalize_name
  before_save :encrypt_password

  validates :name, presence: true
  validates :email, :username, uniqueness: true # move to DB level
  validates :email, format: { with: /\A[\w\d._-]+@[\d\w.]+\.\w+\z/ }
  validates :username, format: { with: /\A[A-Za-z0-9_]+\z/ }
  validates :username, length: { maximum: 40 }
  validates :password, :password_confirmation, presence: true, on: :create
  validates :password, confirmation: true

  def self.authenticate(email, password)
    user = find_by(email: email&.downcase)
    return unless user.present?

    hashed_password = User.hash_to_string(
      OpenSSL::PKCS5.pbkdf2_hmac(
        password, user&.password_salt, ITERATIONS, DIGEST.length, DIGEST
      )
    )
    return unless user.password_hash == hashed_password

    user
  end

  # Служебный метод, преобразует бинарную строку в шестнадцатиричный формат для удобства хранения.
  def self.hash_to_string(password_hash)
    password_hash.unpack1('H*')
  end

  private

  def encrypt_password
    return unless password.present?

    self.password_salt = User.hash_to_string(OpenSSL::Random.random_bytes(16))
    self.password_hash = User.hash_to_string(
      OpenSSL::PKCS5.pbkdf2_hmac(
        password, password_salt, ITERATIONS, DIGEST.length, DIGEST
      )
    )
  end

  def downcase_params
    username&.downcase!
    email&.downcase!
  end

  def normalize_name
    self.name = name.mb_chars.titleize
  end
end
