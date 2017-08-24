require 'yaml'
require 'bcrypt'
require 'fileutils'

puts "enter username"
user = gets.chomp
puts "enter password"
password = gets.chomp

hashed_password = BCrypt::Password.create(password)

root_path = File.expand_path('../', __FILE__)

user_data_path = "./data/#{user}"

if File.directory?(user_data_path)
  puts "Error: user already exists. Please delete from '/data' before proceeding"
else
  FileUtils.mkdir_p(user_data_path)
  FileUtils.mkdir_p(user_data_path + '/custom_clips')
  File.open(user_data_path + '/reminder_list.yml', 'w') { |file| file.write('{}') }
  creds_path = File.expand_path("../users.yml", __FILE__)

  users = YAML.load_file(creds_path, '/users.yml')
  users["#{user}"] = hashed_password.to_s

  File.open(creds_path, "w") do |file|
    file.write users.to_yaml
  end
end
