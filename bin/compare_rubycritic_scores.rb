master_scores = ARGV[0].scan(/(\S+)\s(\S+)\s(\S+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)/)
branch_scores = ARGV[1].scan(/(\S+)\s(\S+)\s(\S+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)/)

def manage_changes_in_scores(branch_scores, master_scores)
  branch_scores.each do |array_change|
    hash_scores(array_change, master_scores)
  end
end

def hash_scores(array_change, master_scores)
  class_array = master_scores.select{|master_score| master_score[2].eql?(array_change[2])}
  if !class_array.empty?
    class_score = class_array.last
    hash_changes_master = { class_score[2] => { "Score" => class_score[0] } }
    hash_changes_branch = { array_change[2] => { "Score" => array_change[0] } }
    compare_scores(hash_changes_master, hash_changes_branch)
  else
    hash_new_classes = { array_change[2] => array_change[0] }
    compare_new_classes_scores(hash_new_classes)
  end
end

def compare_new_classes_scores(hash_new_classes)
  name_class = hash_new_classes.keys.last
  class_scores = hash_new_classes[name_class]
  if class_scores.eql?("F") 
    raise "The score for '#{name_class}' is '#{class_scores}', this class does not meet the required score "
  end
end

def compare_scores(current_scores, new_scores)
  name_class = current_scores.keys.last
  new_scores[name_class].each do |key, new_value|
    if new_value.to_i > current_scores[name_class][key].to_i
      raise "The before value for '#{key}' in the '#{name_class}' class was '#{current_scores[name_class][key].to_i}', now is '#{new_value.to_i}', You've worsened the score"
    end
  end
end

manage_changes_in_scores(branch_scores, master_scores)
