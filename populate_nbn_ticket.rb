require 'yaml'

users = ['dev', 'rhys']

users.each do |user|

def load_reminders_list(user)
  reminder_path = File.expand_path("../data/#{user}/reminder_list.yml", __FILE__)
  YAML.load_file(reminder_path) || {}
end

users.each do |user|
  reminder_path = File.expand_path("../data/#{user}/reminder_list.yml", __FILE__)

  reminders_hash = load_reminders_list(user)

  reminders_hash.each do |date, reminders|
    reminders.each do |reminder|
      reminder[:nbn_search] = ''
    end
  end

  File.open(reminder_path, "w") do |file|
    file.write reminders_hash.to_yaml
  end
end
end


