# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
if Rails.env.development?
  {
    "architect@example.com" => :architect, "developer@example.com" => :developer,
    "tester@example.com" => :security_tester, "head@example.com" => :department_head,
    "reviewer@example.com" => :reviewer
  }.each do |email, role|
    User.find_or_create_by!(email_address: email) { |u| u.password = "password123"; u.role = role }
  end
  puts "Development users created (password: password123)"
end
