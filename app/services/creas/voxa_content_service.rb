module Creas
  class VoxaContentService
    class ServiceError < StandardError
      attr_reader :type, :user_message

      def initialize(message, type: :generic, user_message: nil)
        super(message)
        @type = type
        @user_message = user_message || message
      end
    end

    def initialize(strategy_plan:, target_week: nil)
      @plan = strategy_plan
      @user = @plan.user
      @brand = @plan.brand
      @target_week = target_week
    end

    def call
      # Ensure we have fresh ActiveRecord instances to avoid class reloading issues
      fresh_plan = @plan.is_a?(CreasStrategyPlan) ? CreasStrategyPlan.find(@plan.id) : @plan
      @plan = fresh_plan  # Update instance variable with fresh plan
      @user = @plan.user   # Update user reference from fresh plan
      @brand = @plan.brand # Update brand reference from fresh plan

      Rails.logger.info "Voxa VoxaContentService: Starting content refinement for strategy plan #{@plan.id} (user: #{@user.id}, brand: #{@brand&.id})"

      # Check if strategy is already being processed
      if @plan.status == "processing"
        Rails.logger.warn "Voxa VoxaContentService: Strategy plan #{@plan.id} is already in processing status"
        raise ServiceError.new(
          "Strategy plan #{@plan.id} is already processing",
          type: :already_processing,
          user_message: "Content refinement is already in progress! Please wait a few minutes and refresh the page to see your refined content."
        )
      end

      # Log current content state
      current_content_count = @plan.creas_content_items.count
      Rails.logger.info "Voxa VoxaContentService: Current content items count: #{current_content_count}"

      # Determine batches based on whether we're refining a specific week or all weeks
      if @target_week
        # Single week refinement
        total_batches = 1
        target_batch_number = @target_week
        Rails.logger.info "Voxa VoxaContentService: Starting single week refinement for week #{@target_week} of strategy plan #{@plan.id}"
      else
        # All weeks refinement
        total_batches = calculate_batches_needed
        target_batch_number = 1
        Rails.logger.info "Voxa VoxaContentService: Starting full strategy refinement for strategy plan #{@plan.id} with #{total_batches} batches"
      end

      batch_id = SecureRandom.uuid

      Rails.logger.info "Voxa VoxaContentService: Starting batch processing for strategy plan #{@plan.id} with #{total_batches} batches (batch_id: #{batch_id})"

      # Update strategy plan status to pending (will be updated to processing by first batch job)
      @plan.update!(status: :pending)
      Rails.logger.info "Voxa VoxaContentService: Strategy plan #{@plan.id} status updated to pending"

      # Queue first batch job for Voxa processing
      ::GenerateVoxaContentBatchJob.perform_later(@plan.id, target_batch_number, total_batches, batch_id)
      Rails.logger.info "Voxa VoxaContentService: GenerateVoxaContentBatchJob batch #{target_batch_number}/#{total_batches} queued for strategy plan #{@plan.id}"

      # Return the plan immediately (status: pending)
      @plan
    rescue ServiceError => e
      Rails.logger.error "Voxa VoxaContentService: #{e.message}"
      raise e  # Re-raise ServiceError to be handled by controller
    rescue StandardError => e
      Rails.logger.error "Voxa VoxaContentService: Failed to start content refinement for strategy plan #{@plan.id}: #{e.message}"
      Rails.logger.error "Voxa VoxaContentService: Error backtrace: #{e.backtrace.join("\n")}" if e.backtrace

      error_message = if @target_week
                        "Failed to refine week #{@target_week} content: #{e.message}"
      else
                        "Failed to refine content: #{e.message}"
      end
      raise ServiceError.new(e.message, type: :processing_error, user_message: error_message)
    end

    private

    def calculate_batches_needed
      # Always return 4 batches to organize content by week
      # Each batch will process content items from one specific week
      weekly_plan_count = @plan.weekly_plan&.count || 4

      Rails.logger.info "Voxa VoxaContentService: Strategy plan has #{weekly_plan_count} weeks in weekly_plan"

      # Always use 4 batches to match standard 4-week monthly strategy structure
      4
    end
  end
end
