# Instance variables in controllers are counted like this:

#   1 app/controllers/registrations_controller.rb
#   2 app/controllers/operative/tokens/active_campaigns_controller.rb
#   3 app/controllers/operative/users_controller.rb
#   4 app/controllers/operative/quotations_controller.rb
#   8 app/controllers/advertiser/campaigns_controller.rb

# this script expects to receive the those values separated by spaces
# 1 app/controllers/registrations_controller.rb 2 app/controllers/operative/tokens/active_campaigns_controller.rb

# the scripts compares the scores from the manifest in the master branch
# versus the scores on the current branch, all scores are expected to be
# lower than in the master branch or in the worst case, remain the same.

# Example
#                                         scores from master                                          scores from current branch
# `ruby bin/compare_instance_variables_in_controllers.rb  "1 app/controllers/registrations_controller.rb 2 app/controllers/operative/tokens/active_campaigns_controller.rb"     "1 app/controllers/registrations_controller.rb 2 app/controllers/operative/tokens/active_campaigns_controller.rb"`
#
# if the second parameter (scores from current branch) has one value higher than its pair from
# the master branch, the script will raise an exception.

current_scores = ARGV[0].scan(/\s*(\d+)\s(\D+)/).map{|value,file| [file,value]}.to_h
new_scores = ARGV[1].scan(/\s*(\d+)\s(\D+)/).map{|value,file| [file,value]}.to_h

puts "Comparing instance variables in controllers"

new_scores.each do |key, new_value|
  if new_value.to_i > 1 && new_value.to_i > current_scores[key].to_i
    raise "New instance variables were added, The are now #{new_value} instances in #{key}"
  end
end
