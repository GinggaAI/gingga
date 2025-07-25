require 'json'

current_scores = ARGV[0]
new_scores = ARGV[1]

puts "Comparing Brakeman scores"

def parse_json_for(file_name)
  file = open(file_name, "r")
  json_content = JSON.parse(file.read)
  file.close
  json_content
end

def summary(json_content)
  json_content["warnings"]
    .map { |warning| warning["warning_type"] }
    .group_by { |warning_type| warning_type }
    .tap { |summary| summary["errors"] = json_content.fetch("errors", []) }
end

current_json = parse_json_for(current_scores)
new_json     = parse_json_for(new_scores)

current_summary = summary(current_json)
new_summary = summary(new_json)

new_summary.each do |warning, occurrences|
  #the current summary does not have this type of warnings
  if current_summary[warning].nil?
    raise "New flaws were added, The are now #{occurrences.count} warnings of #{warning}"
  end

  if occurrences.count > current_summary[warning].count
    raise "New flaws were added, The are now #{occurrences.count} warnings of #{warning}" 
  end
end
