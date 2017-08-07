require "sinatra"
require "sinatra/reloader"
require "yaml"
require "bcrypt"
require "date"
require "pry"

def data_path
  if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def reminder_path
  if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/data/reminder_list.yml", __FILE__)
  else
    File.expand_path("../data/reminder_list.yml", __FILE__)
  end
end

def service_type_path
  if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/data/service_types.yml", __FILE__)
  else
    File.expand_path("../data/service_types.yml", __FILE__)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def load_reminder_list
  YAML.load_file(reminder_path)
end

def load_service_types
  YAML.load_file(service_type_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def user_signed_in?
  session[:username]
end

def redirect_unless_signed_in
  unless user_signed_in?
    session[:error] = "You must be signed in to do that."
    redirect "/sign_in"
  end
end

def calculate_date(input)
  date = if input.include?('day')
      Date.today.next_day(input[0].to_i)
    else
      Date.parse(input)
    end
end

configure do
  enable :sessions
  set :session_secret, "0165359735"
end

helpers do
  def current_date
    DateTime.now.strftime "%Y-%m-%d"
  end

  def display_date(date)
    date.strftime "%d-%m-%Y"
  end
end

get "/" do
  redirect_unless_signed_in

  @reminder_list = load_reminder_list
  @service_types = load_service_types

  erb :reminder_list
end

get "/sign_in" do
  erb :sign_in
end

post "/sign_in" do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    redirect "/"
  else
    session[:error] = "Invalid Credentials"
    status 422
    erb :sign_in
  end
end

post "/sign_out" do
  session.delete(:username)

  redirect "/sign_in"
end

post "/add_reminder" do
  reminder_hash = load_reminder_list
  new_reminder = { reference: params[:reference].to_i, service_type: params[:service_type], notes: params[:notes] }

  reminder_date = if params[:date] == 'custom_date'
      calculate_date(params[:customDate])
    else
      calculate_date(params[:date])
    end

  binding.pry

  if reminder_hash[reminder_date] == nil
    reminder_hash[reminder_date] = [new_reminder]
  else
    reminder_hash[reminder_date] << new_reminder
  end

  File.open(reminder_path, "w") do |file|
    file.write reminder_hash.to_yaml
  end

  redirect "/"
end
