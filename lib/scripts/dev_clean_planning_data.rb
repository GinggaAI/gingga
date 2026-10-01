# Development Only: Clean all planning and content data
#
# Usage:
#   bundle exec rails runner lib/scripts/dev_clean_planning_data.rb
#
# This script will:
# 1. Delete all CreasContentItem records
# 2. Delete all CreasStrategyPlan records
# 3. Delete related AiResponse records for planning/voxa
# 4. Show summary of what was deleted

unless Rails.env.development?
  puts "❌ ERROR: This script can only run in development environment!"
  puts "Current environment: #{Rails.env}"
  exit 1
end

puts "=" * 80
puts "🧹 DEVELOPMENT DATA CLEANUP - Planning & Content Strategy"
puts "=" * 80
puts ""
puts "⚠️  WARNING: This will delete ALL planning data in development!"
puts ""
puts "This includes:"
puts "  • All Content Items (CreasContentItem)"
puts "  • All Strategy Plans (CreasStrategyPlan)"
puts "  • Related AI Responses (Noctua/Voxa)"
puts ""
print "Are you sure you want to continue? (type 'yes' to confirm): "

confirmation = STDIN.gets.chomp

unless confirmation.downcase == 'yes'
  puts "\n❌ Cleanup cancelled."
  exit 0
end

puts "\n" + "=" * 80
puts "Starting cleanup..."
puts "=" * 80

# Count records before deletion
content_items_count = CreasContentItem.count
strategy_plans_count = CreasStrategyPlan.count
ai_responses_count = AiResponse.where(service_name: ['noctua', 'voxa']).count

puts "\n📊 Current counts:"
puts "  • Content Items: #{content_items_count}"
puts "  • Strategy Plans: #{strategy_plans_count}"
puts "  • AI Responses (Noctua/Voxa): #{ai_responses_count}"
puts ""

# Delete in correct order (child records first)
print "🗑️  Deleting Content Items... "
CreasContentItem.delete_all
puts "✅ Done (#{content_items_count} deleted)"

print "🗑️  Deleting Strategy Plans... "
CreasStrategyPlan.delete_all
puts "✅ Done (#{strategy_plans_count} deleted)"

print "🗑️  Deleting AI Responses (Noctua/Voxa)... "
deleted_responses = AiResponse.where(service_name: ['noctua', 'voxa']).delete_all
puts "✅ Done (#{deleted_responses} deleted)"

# Verify deletion
remaining_content = CreasContentItem.count
remaining_plans = CreasStrategyPlan.count
remaining_responses = AiResponse.where(service_name: ['noctua', 'voxa']).count

puts "\n" + "=" * 80
puts "✅ CLEANUP COMPLETE"
puts "=" * 80
puts "\n📊 Final counts:"
puts "  • Content Items: #{remaining_content}"
puts "  • Strategy Plans: #{remaining_plans}"
puts "  • AI Responses (Noctua/Voxa): #{remaining_responses}"
puts ""

if remaining_content == 0 && remaining_plans == 0
  puts "✅ All planning data successfully deleted!"
  puts "You can now test from scratch with a clean slate."
else
  puts "⚠️  Warning: Some records remain. Please check manually."
end

puts "\n" + "=" * 80
puts "Summary:"
puts "  ✅ Deleted #{content_items_count} content items"
puts "  ✅ Deleted #{strategy_plans_count} strategy plans"
puts "  ✅ Deleted #{deleted_responses} AI responses"
puts "=" * 80
puts ""
