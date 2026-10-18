# Creates the first user. Credentials come from the environment so they are
# never committed:
#
#   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=... [ADMIN_USERNAME=admin] bin/rails db:seed
#
# Without them the seed is skipped (db:prepare runs seeds on a fresh database,
# including on the first start of the Docker container).

def create_admin_user
  count = User.count
  if count.positive?
    puts "create_admin_user: You already have #{count} user(s) in database."
    return
  end

  email = ENV["ADMIN_EMAIL"].presence
  password = ENV["ADMIN_PASSWORD"].presence
  unless email && password
    puts "create_admin_user: skipped, set ADMIN_EMAIL and ADMIN_PASSWORD to create the first user."
    return
  end

  User.create!(email: email, password: password, password_confirmation: password,
               username: ENV.fetch("ADMIN_USERNAME", "admin"))
  puts "create_admin_user: created #{email}"
end

create_admin_user
