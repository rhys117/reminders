require 'yaml'

users = ['rhys']

users.each do |user|
  reminder_path = File.expand_path("../data/#{user}/reminder_list.yml", __FILE__)

  def load_reminders_list
    reminder_path = File.expand_path("../data/#{user}/reminder_list.yml", __FILE__)
    YAML.load_file(reminder_path) || {}
  end

  reminders_hash = load_reminders_list

  reminders_hash.each do |date, reminders|
    reminders.each do |reminder|
      reminder[:nbn_ticket] = 0
    end
  end

  File.open(reminder_path, "w") do |file|
    file.write reminders_hash.to_yaml
  end
end
