# Creates the admin user when no user with ADMIN_USERNAME (default "admin")
# exists. Credentials come from the environment so they are never committed:
#
#   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=... [ADMIN_USERNAME=admin] bin/rails db:seed
#
# `make run` and `make docker-up` generate them in .env (bin/setup-env).
# An existing admin user is left unchanged, including its password.

def create_admin_user
  username = ENV["ADMIN_USERNAME"].presence || "admin"
  if User.where("lower(username) = ?", username.downcase).exists?
    puts "create_admin_user: user '#{username}' already exists."
    return
  end

  email = ENV["ADMIN_EMAIL"].presence
  password = ENV["ADMIN_PASSWORD"].presence
  unless email && password
    puts "create_admin_user: skipped, set ADMIN_EMAIL and ADMIN_PASSWORD to create user '#{username}'."
    return
  end

  user = User.new(email: email, password: password, password_confirmation: password, username: username)
  if user.save
    puts "create_admin_user: created user '#{username}' <#{email}> with the password from ADMIN_PASSWORD."
  else
    puts "create_admin_user: could not create user '#{username}': #{user.errors.full_messages.to_sentence}"
  end
end

create_admin_user
