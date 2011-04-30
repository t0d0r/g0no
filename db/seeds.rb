# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

def create_admin_user
  count =  User.count
  if count < 1
    puts "create_admin_user: email: admin@bstconsult.com, password: 123456"
    User.create!( :email => 'admin@bstconsult.com', 
                 :password => '123456', :password_confirmation => '123456', 
                 :username => 'admin' )
  else 
    puts "create_admin_user: You already have #{count} user(s) in database."
  end
end

create_admin_user
