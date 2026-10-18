class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  normalizes :username, with: ->(username) { username.strip.presence }

  validates :username, uniqueness: { case_sensitive: false }, allow_nil: true

  # The sign-in form has one field, which may hold the username or the email.
  def self.find_for_database_authentication(conditions)
    value = conditions[authentication_keys.first].to_s.strip.downcase
    where("lower(username) = :value OR lower(email) = :value", value: value).first
  end

  def display_name
    username.presence || email
  end
end
