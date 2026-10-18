# Creates the admin user when no user with ADMIN_USERNAME (default "admin")
# exists. Credentials come from the environment so they are never committed:
#
#   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=... [ADMIN_USERNAME=admin] bin/rails db:seed
#
# `make run` and `make docker-up` generate them in .env (bin/setup-env).
# An existing admin user keeps its email and password; the seed only makes
# sure it has the admin flag, which opens the admin panel (/admin).

def create_admin_user
  username = ENV["ADMIN_USERNAME"].presence || "admin"
  existing = User.where("lower(username) = ?", username.downcase).first
  if existing
    if existing.admin?
      puts "create_admin_user: user '#{username}' already exists."
    else
      existing.update_column(:admin, true)
      puts "create_admin_user: user '#{username}' already exists; marked as administrator."
    end
    return
  end

  email = ENV["ADMIN_EMAIL"].presence
  password = ENV["ADMIN_PASSWORD"].presence
  unless email && password
    puts "create_admin_user: skipped, set ADMIN_EMAIL and ADMIN_PASSWORD to create user '#{username}'."
    return
  end

  user = User.new(email: email, password: password, password_confirmation: password, username: username, admin: true)
  if user.save
    puts "create_admin_user: created user '#{username}' <#{email}> with the password from ADMIN_PASSWORD."
  else
    puts "create_admin_user: could not create user '#{username}': #{user.errors.full_messages.to_sentence}"
  end
end

create_admin_user
