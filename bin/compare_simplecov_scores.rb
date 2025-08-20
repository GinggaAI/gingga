#Reads the files wiouth the first line containing the titles
lines_in_new_report = open("coverage/results.csv","r").read.split(/\n/)[1..-1]
lines_in_master_report = open("coverage_results.csv","r").read.split(/\n/)[1..-1]

=begin

File,% covered,Lines,Relevant Lines,Lines covered,Lines missed
"./app/channels/application_cable/channel.rb",0,4,4,0,4
"./app/channels/application_cable/connection.rb",0,4,4,0,4

=end

def build_hash_from_line(line)
  # line => "./app/channels/application_cable/channel.rb",0,4,4,0,4
  # result => {file: "./app/channels/application_cable/channel.rb",
  #            covered: 0}

  file_name, percentage = line.split(",")
  {file: file_name, covered: percentage}
end

def lines_to_hashes(lines)
  lines.map{ |line| build_hash_from_line(line) }
end

files_in_new_report = lines_to_hashes(lines_in_new_report)
files_in_master_report = lines_to_hashes(lines_in_master_report)


files_in_new_report.each do |file_in_new_report|
  file_in_master_report = files_in_master_report.select{|file_in_master| file_in_new_report[:file].eql?(file_in_master[:file]) }
  if file_in_master_report.empty? # new file
    if file_in_new_report[:covered].to_f <= 90.0
      raise "The minimum code coverage accepted is 90% but #{file_in_new_report[:file]} is #{file_in_new_report[:covered]}"
    end
  else
    if file_in_new_report[:covered].to_f < file_in_master_report.first[:covered].to_f
      raise "The coverage for #{file_in_new_report[:file]} has worsened, it was #{file_in_master_report.first[:covered]} and now is #{file_in_new_report[:covered]}"
    end
  end
end
