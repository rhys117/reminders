require "sinatra"
require "sinatra/reloader"
require "sinatra/config_file"
require "yaml"
require "bcrypt"
require "date"
require "pry"

config_file File.expand_path('../config.yml', __FILE__)

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

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def load_reminders_list
  YAML.load_file(reminder_path) || {}
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

def calculate_date(radio_date, custom_date)
  unless radio_date == nil
    Date.today.next_day(radio_date[0].to_i) if radio_date.include?('day')
  else
    Date.parse(custom_date)
  end
end

def next_element_id(array)
  if array
    max = array.map { |reminder_hash| reminder_hash[:id] }.max || 0
    return max + 1
  else
    0
  end
end

def set_service_type(params)
  vocus = params[:is_vocus?] || false
  if vocus
    "#{params[:service_type]} (VOCUS)"
  else
    params[:service_type]
  end
end

def error_message(params)
  service_type = params[:service_type] || false
  reference = true unless params[:reference].strip.empty?
  notes = true unless params[:notes].strip.empty?

  return 'You must specify a service type' unless service_type
  return 'You must specify a reference number' unless reference
  return 'You must specify some notes' unless notes
  false
end

def generate_new_reminder_hash(params, reminders_hash, reminder_date, service_type)
  { id: next_element_id(reminders_hash[reminder_date]),
     reference: params[:reference].strip.to_i,
     vocus_ticket: params[:vocus_ticket].strip.to_i,
     service_type: service_type,
     priority: params[:priority],
     notes: params[:notes].strip,
     complete: false }
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

  def date_classes(date)
    return "past_date" if date < Date.today
    "future_date" if date > Date.today
  end

  def inverse_complete_value(reminder)
    return 'incomplete' if reminder[:complete]
    return 'complete' if !reminder[:complete]
  end

  def sort_reminders(reminders, &block)
    complete_reminders, incomplete_reminders = reminders.partition { |reminder| reminder[:complete] }

    incomplete_reminders.sort_by { |reminder| reminder[:priority] }.reverse.each(&block)
    complete_reminders.sort_by { |reminder| reminder[:priority] }.reverse.each(&block)
  end

  def reference_url(ref)
    settings.reference_url + ref.to_s
  end

  def vocus_url(ref)
    settings.vocus_url + ref.to_s
  end

  def checked(param_value, value)
    return 'checked' if param_value == value
  end

  def reminder_classes(reminder)
    classes = ''
    classes << 'complete ' if reminder[:complete]
    classes << "priority_#{reminder[:priority]} "
    classes
  end
end

get "/" do
  redirect_unless_signed_in

  @reminder_list = load_reminders_list

  erb :reminder_list
end

get "/sign_in" do
  erb :sign_in
end

post "/sign_in" do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:success] = "Welcome"
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
  reminders_hash = load_reminders_list
  reminder_date = calculate_date(params[:date], params[:custom_date])

  error = error_message(params)
  if error
    session[:error] = error

    @reminder_list = load_reminders_list
    erb :reminder_list
  else
    service_type = set_service_type(params)
    new_reminder = generate_new_reminder_hash(params, reminders_hash, reminder_date, service_type)

    if reminders_hash[reminder_date] == nil
      reminders_hash[reminder_date] = [new_reminder]
    else
      reminders_hash[reminder_date] << new_reminder
    end

    File.open(reminder_path, "w") do |file|
      file.write reminders_hash.to_yaml
    end

    session[:success] = "#{service_type.upcase} #{params[:notes]} <br/> #{display_date(reminder_date)}"
    redirect "/"
  end
end

get "/:date/:id/complete" do
  id = params[:id].to_i

  date = Date.parse(params[:date])

  reminders_hash = load_reminders_list

  reminder_index = reminders_hash[date].index { |reminders| reminders[:id] == id }
  reminders_hash[date][reminder_index][:complete] = true

  File.open(reminder_path, "w") do |file|
    file.write reminders_hash.to_yaml
  end
  session[:success] = "Reminder Marked as Complete"
  redirect "/"
end

get "/:date/:id/incomplete" do
  id = params[:id].to_i
  date = Date.parse(params[:date])
  reminders_hash = load_reminders_list

  reminder_index = reminders_hash[date].index { |reminder| reminder[:id] == id }
  reminders_hash[date][reminder_index][:complete] = false

  File.open(reminder_path, "w") do |file|
    file.write reminders_hash.to_yaml
  end
  session[:success] = "Reminder Marked as Incomplete"
  redirect "/"
end

post "/:date/:id/delete" do
  id = params[:id].to_i
  date = Date.parse(params[:date])

  reminders_hash = load_reminders_list

  reminder_index = reminders_hash[date].index { |reminder| reminder[:id] == id }
  reminders_hash[date].delete_at(reminder_index)

  reminders_hash.reject! { |_, reminders_array| reminders_array.empty? }

  File.open(reminder_path, "w") do |file|
    file.write reminders_hash.to_yaml
  end
  session[:success] = "Reminder deleted"
  redirect "/"
end

post "/delete_all_complete" do
  reminders_hash = load_reminders_list

  reminders_hash.each do |_, reminders_array|
    reminders_array.reject! { |reminder| reminder[:complete] }
  end

  reminders_hash.reject! { |_, reminders_array| reminders_array.empty? }

  File.open(reminder_path, "w") do |file|
    file.write reminders_hash.to_yaml
  end
  session[:success] = "All completed reminders deleted"
  redirect "/"
end

# super messy must be refactored
post "/make_incomplete_current" do
  reminders_hash = load_reminders_list

  today = Date.today

  out_of_date = []
  reminders_hash.each do |date, reminders|
    if date < today
      reminders.each do |reminder|
        unless reminder[:complete]
          out_of_date << reminder
          reminder_index = reminders_hash[date].index { |re| reminder[:id] == re[:id] }
          reminders_hash[date].delete_at(reminder_index)
        end
      end
    end
  end

  reminders_hash[today] = [] if reminders_hash[today] == nil

  out_of_date.each do |reminder|
    reminder[:id] = next_element_id(reminders_hash[today])
    reminders_hash[today] << reminder
  end

  reminders_hash.reject! { |_, reminders_array| reminders_array.empty? }

  File.open(reminder_path, "w") do |file|
    file.write reminders_hash.to_yaml
  end
  session[:success] = "All past incomplete reminders moved to today"
  redirect "/"
end