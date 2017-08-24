require 'yaml'
require 'bcrypt'
require 'fileutils'

puts "enter username"
user = gets.chomp
puts "enter password"
password = gets.chomp

hashed_password = BCrypt::Password.create(password)

reminder_path = File.expand_path("../data/#{user}/reminder_list.yml", __FILE__)

dirname = File.dirname(reminder_path)
unless File.directory?(dirname)
  FileUtils.mkdir_p(dirname)
end


File.open(reminder_path, "w") do |file|
  file.write reminders_hash.to_yaml
end

File.open
