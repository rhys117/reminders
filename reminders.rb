require "sinatra"
require "sinatra/reloader"
require "yaml"
require "bcrypt"

def data_path
  if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
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

configure do
  enable :sessions
  set :session_secret, "0165359735"
end

helpers do
  
end

get "/" do
  redirect_unless_signed_in

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
